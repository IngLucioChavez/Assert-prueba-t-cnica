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



