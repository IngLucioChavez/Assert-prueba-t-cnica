# Arquitectura de autenticación y comunicación entre servicios

**Escenario:** Assert está migrando su sistema monolítico de cobranza a microservicios.
Este documento cubre el diseño del módulo de autenticación (JWT + refresh tokens) y
cómo se comunican los servicios entre sí una vez separados.

Convención usada en los diagramas (según el requisito complementario RF-33):
- `auth-core` — el servicio que emite y firma los tokens.
- `svc-mesh-assert` — el gateway/mesh interno por el que pasan las llamadas entre servicios.

---

## 1. Flujo completo de autenticación con JWT + refresh tokens

**Dónde se generan:** únicamente en `auth-core`. Es el único servicio con la clave
privada de firma; ningún otro servicio emite ni re-firma tokens. Al hacer login exitoso,
`auth-core` genera dos tokens distintos, con propósitos distintos:

- **access_token**: JWT firmado (RS256, no HS256 — la razón está en la sección 2),
  vida corta (10–15 min), con claims `sub` (id de usuario), `roles`/`scopes`, `iat`, `exp`
  y un `kid` en el header para poder rotar claves de firma sin invalidar tokens viejos.
- **refresh_token**: token de vida larga (7–30 días), guardado *hasheado* en la base de
  `auth-core` junto con metadata (device, IP, fecha de emisión) para poder auditar y
  revocar sesiones individuales.

**Cómo viajan:**

```
 Cliente (SPA / app móvil)
    |
    | 1. POST /login  { usuario, password }              [HTTPS]
    v
+-----------+
| auth-core |
+-----------+
    |
    | 2. 200 OK
    |    body:    { access_token }
    |    Set-Cookie: refresh_token (HttpOnly; Secure; SameSite=Strict)
    v
 Cliente
    |
    | 3. GET /cuentas
    |    Header: Authorization: Bearer <access_token>
    v
+---------------------+
|   svc-mesh-assert    |   <- gateway interno: aquí se valida la firma
|  (valida JWT contra  |      del JWT contra el JWKS público de auth-core,
|   JWKS de auth-core) |      sin llamar a auth-core en cada request
+---------------------+
    |            |              |
    v            v              v
+---------+  +--------------+  +-------------+
|Servicio |  |Servicio      |  |Servicio     |
|Clientes |  |Transacciones |  |Cobranza     |
+---------+  +--------------+  +-------------+

 Cuando el access_token expira (401 token_expired):
 Cliente ---- 4. POST /refresh (cookie refresh_token) ----> auth-core
 auth-core --- 5. nuevo access_token (+ refresh_token rotado) ---> Cliente
```

**Dónde se validan:** la firma se valida en `svc-mesh-assert` (o en un sidecar/middleware
compartido que corre junto a cada servicio dentro de la malla), usando la clave *pública*
de `auth-core` obtenida de su endpoint JWKS (`/.well-known/jwks.json`) y cacheada
localmente con una rotación periódica. Esto es deliberado: si cada validación de token
tuviera que llamar a `auth-core` de vuelta, `auth-core` se volvería un cuello de botella y
un punto único de falla para *todo* el tráfico del sistema — con JWT firmado, cualquier
servicio puede validar de forma local y offline con solo la clave pública.

---

## 2. Dónde almacenar el refresh_token

Las dos opciones típicas y sus implicaciones:

- **localStorage / sessionStorage:** accesible desde JavaScript, lo que lo hace
  vulnerable a XSS — basta con que una sola dependencia del frontend tenga una
  vulnerabilidad de inyección de script para que un atacante exfiltre el refresh_token
  de todos los usuarios activos en ese momento. Para un sistema que mueve dinero
  (cobranza de créditos), ese es un riesgo que no vale la pena asumir solo por
  simplicidad de implementación.
- **Cookie `HttpOnly` + `Secure` + `SameSite=Strict`:** no accesible desde JavaScript
  (mitiga el robo por XSS), viaja automáticamente solo al dominio de `auth-core`, y
  `SameSite=Strict` reduce el riesgo de CSRF al no enviarse en navegaciones
  cross-site. La contra es operativa: requiere que `auth-core` y el frontend compartan
  dominio o subdominio (o configurar CORS + cookies cross-site con cuidado), y "cerrar
  sesión" ya no es un simple `localStorage.removeItem` — necesita un endpoint que
  invalide la cookie y revoque el token del lado del servidor.

**Decisión:** cookie `HttpOnly` + `Secure` + `SameSite=Strict`, combinada con una lista
de refresh tokens activos por usuario en `auth-core` (no solo confiar en la firma/expiración
del token). Esto permite ofrecer "cerrar sesión en todos los dispositivos" — algo que en
un sistema de cobranza importa de verdad: si el dispositivo de un cobrador se pierde o se
compromete, alguien de operaciones debe poder revocar esa sesión sin depender de que el
token expire solo.

---

## 3. Comunicación interna: Servicio A llamando a Servicio B

**No** se reenvía el token del usuario tal cual, por dos razones concretas:

1. **Vida útil:** el access_token del usuario dura 10–15 minutos. Una cadena de llamadas
   internas (A → B → C) podría fallar a media operación si el usuario quedó inactivo un
   momento, aunque el usuario nunca debería enterarse de esa dependencia interna.
2. **Alcance (scope):** el JWT del usuario lleva los permisos *del usuario*, no
   necesariamente los que el Servicio A necesita para hablar con B. Si B confía
   ciegamente en la firma de cualquier JWT válido, un usuario que nunca debería poder
   invocar una función interna de B podría hacerlo directamente si consigue ese endpoint,
   porque técnicamente su token "es válido".

**Enfoque:** separar la identidad del servicio de la identidad del usuario, y propagar
ambas:

- Cada servicio tiene su propia identidad ante `auth-core` (client credentials, o
  certificados mTLS dentro de `svc-mesh-assert`) — esto prueba *quién llama* (Servicio A)
  ante B, independientemente de qué usuario originó la petición.
- El contexto del usuario original se propaga por separado: la forma robusta es un patrón
  de intercambio de token (equivalente a OAuth2 Token Exchange, RFC 8693), donde
  `auth-core` emite un token de servicio con un claim `act` (actor) que indica "A actúa en
  nombre del usuario X". Así B puede aplicar autorización en dos capas — ¿A tiene permiso
  de llamarme? ¿el usuario en cuyo nombre actúa A tiene permiso sobre este recurso? — y
  queda un rastro de auditoría claro, algo crítico en cobranza para poder responder "quién,
  y en nombre de quién, modificó este saldo".
- Como paso intermedio más simple (dado que es una migración gradual, no un rediseño
  desde cero): reenviar el JWT de usuario en llamadas internas dentro de `svc-mesh-assert`,
  pero *nunca* fuera de la red interna, y con mTLS entre servicios para que ningún servicio
  no autorizado pueda inyectarse en la malla y reproducir tokens capturados.

---

## 4. Vulnerabilidad en el middleware de verificación JWT

```js
app.use((req, res, next) => {
  const token = req.headers['authorization'];
  const decoded = jwt.decode(token);   // <-- observa esta linea
  req.user = decoded;
  next();
});
```

`jwt.decode()` **no verifica la firma** — solo hace base64-decode del payload. No
comprueba que el token haya sido emitido por `auth-core`, ni que no haya expirado, ni que
el algoritmo declarado sea el esperado. Cualquiera puede construir a mano un JWT con
`{ "sub": "cualquiera", "roles": ["admin"] }`, en base64, sin firma válida, y este
middleware lo aceptaría igual. En la práctica esto equivale a no tener autenticación:
cualquier request con un header `Authorization` bien formado (pero falso) pasa como si
fuera un usuario legítimo — y en un sistema financiero eso significa que un atacante
podría forjarse a sí mismo permisos de administrador.

**Corrección:**

```js
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
  jwksUri: 'https://auth-core.assert.internal/.well-known/jwks.json',
});

function obtenerClavePublica(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) return callback(err);
    callback(null, key.getPublicKey());
  });
}

app.use((req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token no proporcionado' });
  }

  const token = authHeader.slice('Bearer '.length);

  // jwt.verify (no jwt.decode) valida firma, expiracion y, con `algorithms`
  // fijado explicitamente, evita el ataque de "algorithm confusion" (donde
  // alguien manda un token con alg=HS256 y usa la clave publica RSA como si
  // fuera el secreto HMAC).
  jwt.verify(token, obtenerClavePublica, { algorithms: ['RS256'] }, (err, decoded) => {
    if (err) {
      return res.status(401).json({ error: 'Token invalido o expirado' });
    }
    req.user = decoded;
    next();
  });
});
```

Cambios además de `decode` → `verify`: se valida que el header traiga el prefijo
`Bearer `, y se fija explícitamente `algorithms: ['RS256']` en vez de dejar que la
librería acepte cualquier algoritmo que el token declare.

---

## 5. Expirar tokens sin forzar login cada hora

Estrategia de **access token corto + refresh silencioso + rotación con detección de reuso**:

- El access_token vive poco (10–15 min) a propósito: si se filtra (por ejemplo en un log
  mal configurado), la ventana de abuso es de minutos, no de horas.
- El cliente implementa un interceptor HTTP: al recibir un 401 con código
  `token_expired`, llama automáticamente a `POST /refresh` (la cookie del refresh_token
  viaja sola), obtiene un access_token nuevo, y reintenta la petición original una sola
  vez. El usuario nunca ve una pantalla de login mientras siga activo.
- **Rotación por uso:** cada vez que se usa un refresh_token, `auth-core` lo invalida y
  emite uno nuevo en su lugar. Si un refresh_token ya usado se vuelve a presentar (por
  ejemplo, porque alguien lo robó y lo reutilizó después de que el usuario legítimo ya
  renovó), se interpreta como señal de robo y se revocan *todas* las sesiones activas de
  ese usuario — es el patrón estándar de reuse detection en OAuth2.
- El refresh_token tiene una ventana deslizante pero con un tope absoluto (renovable
  mientras haya actividad, pero nunca más de, por ejemplo, 90 días sin volver a
  autenticarse con credenciales), para acotar cuánto puede durar una sesión comprometida
  que nadie ha detectado todavía.
