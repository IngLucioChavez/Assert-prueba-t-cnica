create database assert;

-- =============================================
-- TABLA: clientes
-- =============================================
CREATE TABLE clientes (
    id_cliente BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100),
    email VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estatus boolean not null default true -- para eliminación lógica
);


-- =============================================
-- TABLA: tipos_cuenta
-- catalogo para definir tipos de cuentas
-- =============================================
CREATE TABLE tipos_cuenta (
    id_tipo_cuenta BIGSERIAL PRIMARY key,
    descripcion VARCHAR(255),
    estatus boolean not null default true, --eliminación lógica
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLA: cuentas
-- Un cliente puede tener varias cuentas
-- =============================================
CREATE TABLE cuentas (
    id_cuenta BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT NOT NULL,
    id_tipo_cuenta bigint not null,
    numero_cuenta VARCHAR(30) NOT NULL UNIQUE,
    saldo NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cuentas_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON DELETE RESTRICT, --impide eliminar registros padre si existen registros hijos
    
    constraint fk_cuentas_tipos_cuenta
    	foreign key (id_tipo_cuenta)
    	references tipos_cuenta(id_tipo_cuenta),

    CONSTRAINT chk_cuentas_saldo
        CHECK (saldo >= 0)
);


-- =============================================
-- TABLA: transacciones
-- Una cuenta puede tener muchas transacciones
-- =============================================
CREATE TABLE transacciones (
    id_transaccion BIGSERIAL PRIMARY KEY,
    id_cuenta BIGINT NOT NULL,
    concepto varchar(100) null,
    tipo VARCHAR(10) NOT NULL,
    monto NUMERIC(15, 2) NOT NULL,
    referencia VARCHAR(100) null,
    fecha TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_transacciones_cuenta
        FOREIGN KEY (id_cuenta)
        REFERENCES cuentas(id_cuenta)
        ON DELETE RESTRICT,

    CONSTRAINT chk_transacciones_tipo
        CHECK (tipo IN ('DEPOSITO', 'RETIRO', 'PAGO')), --validación tipo de transaccion valida

    CONSTRAINT chk_transacciones_monto
        CHECK (monto > 0)
);


-- =============================================
-- ÍNDICES
-- =============================================

-- Para consultar rápidamente las cuentas de un cliente
CREATE INDEX idx_cuentas_cliente_id
ON cuentas(id_cliente);

-- Para consultar los movimientos de una cuenta
CREATE INDEX idx_transacciones_cuenta_id
ON transacciones(id_cuenta);

-- Útil para obtener el historial de una cuenta ordenado por fecha
CREATE INDEX idx_transacciones_cuenta_fecha
ON transacciones(id_cuenta, fecha DESC);

-- Para búsquedas por tipo
CREATE INDEX idx_transacciones_concepto_pago_id
ON transacciones(tipo);


-- =============================================
-- FUNCIÓN PARA ACTUALIZAR updated_at
-- =============================================
CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================
-- TRIGGERS
-- - para cada vez que se modifique un registro actualizar fecha de modificación =
-- =============================================

CREATE TRIGGER trg_clientes_updated_at
BEFORE UPDATE ON clientes
FOR EACH ROW
EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trg_cuentas_updated_at
BEFORE UPDATE ON cuentas
FOR EACH ROW
EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trg_conceptos_pago_updated_at
BEFORE UPDATE ON tipos_cuenta
FOR EACH ROW
EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trg_transacciones_updated_at
BEFORE UPDATE ON transacciones
FOR EACH ROW
EXECUTE FUNCTION actualizar_updated_at();


-- INSERTS

-- =============================================
-- CLIENTES
-- =============================================

INSERT INTO clientes
    (nombre, apellido_paterno, apellido_materno, email, telefono)
VALUES
    ('Lucio', 'Chávez', 'García', 'lucio.chavez@email.com', '5512345678'),
    ('Carlos', 'Hernández', 'López', 'carlos.hernandez@email.com', '5523456789'),
    ('María', 'González', 'Martínez', 'maria.gonzalez@email.com', '5534567890'),
    ('Ana', 'Ramírez', 'Torres', 'ana.ramirez@email.com', '5545678901'),
    ('Jorge', 'Martínez', 'Sánchez', 'jorge.martinez@email.com', '5556789012');

-- =============================================
-- TIPOS CUENTA
-- =============================================
insert into tipos_cuenta
	(descripcion)
values
	('AHORRO'),
	('NOMINA'),
	('CHEQUES'),
	('CREDITO');


-- =============================================
-- CUENTAS
-- =============================================
truncate table cuentas restart identity;
INSERT INTO cuentas
    (id_cliente, id_tipo_cuenta, numero_cuenta, saldo, activa)
VALUES
    (1, 2,'000100000001', 25000.00, TRUE),
    (2, 2,'000100000002', 15000.50, TRUE),
    (3, 2,'000100000003', 32500.75, TRUE),
    (4, 4,'000100000004', 8500.00, TRUE),
    (5, 1,'000100000005', 12000.25, TRUE);

-- =============================================
-- TRANSACCIONES
-- =============================================

INSERT INTO transacciones
    (id_cuenta, concepto, tipo, monto, referencia)
VALUES
    (3, 'NOMINA 1 AGOSTO',  'DEPOSITO', 10000.00, 'DEP-000001'),
    (4, 'GASOLINA',  'RETIRO',    2500.00, 'RET-000001'),
    (5, 'NOMINA 1 AGOSTO',     'DEPOSITO',      850.00,  'PAG-000001'),
    (6, 'PAGO AGOSTO',     'PAGO',      650.00,  'PAG-000002'),
    (7, 'MERCADO LIBRE',     'RETIRO',      3000.00, 'PAG-000003');

INSERT INTO transacciones
    (id_cuenta, concepto, tipo, monto, referencia)
VALUES
    (3, 'NOMINA 1 AGOSTO',  'DEPOSITO', 100.00, 'DEP-000001'),
	(3, 'NOMINA 1 AGOSTO',  'DEPOSITO', 100.00, 'DEP-000001'),
	(3, 'NOMINA 1 AGOSTO',  'DEPOSITO', 100.00, 'DEP-000001');

INSERT INTO transacciones
    (id_cuenta, concepto, tipo, monto, referencia)
VALUES
    (4, 'NOMINA 1 AGOSTO',  'DEPOSITO', 10.00, 'DEP-000001'),
	(4, 'NOMINA 1 AGOSTO',  'DEPOSITO', 50.00, 'DEP-000001');

alter table cuentas 
	add column fecha_limite timestamp null;

update cuentas set fecha_limite = '2026-07-15 00:00:00' where id_cuenta = 3;
update cuentas set fecha_limite = '2026-09-10 00:00:00' where id_cuenta = 4;
update cuentas set fecha_limite = '2026-08-15 00:00:00' where id_cuenta = 5;
update cuentas set fecha_limite = '2026-09-1 00:00:00' where id_cuenta = 6;
update cuentas set fecha_limite = '2026-09-20 00:00:00' where id_cuenta = 7;



-- =============================================
-- CONSULTAS
-- =============================================

-- a) cuentas vencidas
select 
	CONCAT(clientes.nombre,' ',clientes.apellido_paterno,' ',clientes.apellido_materno ) as nombre,
	saldo,
	extract(day from (now() - cuentas.fecha_limite)) as dias_atraso
from cuentas
inner join clientes on clientes.id_cliente = cuentas.id_cliente 
where saldo > 0 and fecha_limite < now();

-- b) top 5 clientes por volumen transaccionado
select 
	CONCAT(c.nombre,' ',c.apellido_paterno,' ',c.apellido_materno ) as nombre, c.id_cliente, count(t.id_transaccion) as transacciones
from clientes c
inner join cuentas cu on cu.id_cliente = c.id_cliente 
inner join transacciones t on t.id_cuenta = cu.id_cuenta
where t.fecha > now() - interval '30 days'
group by c.id_cliente
order by transacciones desc
limit 5;

-- c) posibles transacciones duplicadas

select 
	cl.id_cliente, 
	cl.nombre, 
	t1.id_transaccion AS transaccion_1, 
	t2.id_transaccion AS transaccion_2, 
	t1.monto, 
	t1.fecha AS fecha_1, 
	t2.fecha AS fecha_2, 
	ABS(EXTRACT(EPOCH FROM (t1.fecha - t2.fecha))) AS diferencia_segundos
from transacciones t1
inner join transacciones t2 
	on t1.id_transaccion < t2.id_transaccion
	and t1.monto  = t2.monto
	and ABS(EXTRACT(EPOCH FROM (t1.fecha - t2.fecha))) < (5*60) --5 minutos
inner join cuentas c1
	on c1.id_cuenta = t1.id_cuenta
inner join cuentas c2
	on c2.id_cuenta = t2.id_cuenta
	and c1.id_cuenta = c2.id_cuenta
inner join clientes cl
	on cl.id_cliente = c1.id_cliente
order by diferencia_segundos;


