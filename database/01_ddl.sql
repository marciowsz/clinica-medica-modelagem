-- =============================================================
-- Clinica Medica - MODELO LOGICO (DDL) normalizado ate a 3FN
-- SGBD: PostgreSQL 16+
--   createdb clinica_medica
--   psql -d clinica_medica -f database/01_ddl.sql
-- =============================================================

DROP TABLE IF EXISTS pagamentos, prescricoes, medicamentos, prontuarios,
                     consultas, medicos, especialidades,
                     paciente_telefones, pacientes CASCADE;

-- -------------------------------------------------------------
-- ESPECIALIDADES
-- 3FN: a descricao depende da especialidade, nao do medico.
--      Por isso sai da tabela medicos e vira tabela propria.
-- -------------------------------------------------------------
CREATE TABLE especialidades (
    id         SERIAL       PRIMARY KEY,
    nome       VARCHAR(60)  NOT NULL UNIQUE,
    descricao  VARCHAR(200)
);

-- -------------------------------------------------------------
-- PACIENTES
-- -------------------------------------------------------------
CREATE TABLE pacientes (
    id               SERIAL       PRIMARY KEY,
    nome             VARCHAR(120) NOT NULL,
    cpf              CHAR(11)     NOT NULL UNIQUE CHECK (cpf ~ '^[0-9]{11}$'),
    data_nascimento  DATE         NOT NULL,
    email            VARCHAR(120) UNIQUE
);

-- -------------------------------------------------------------
-- PACIENTE_TELEFONES
-- 1FN: telefone e um atributo MULTIVALORADO (o paciente tem
--      celular, residencial...). Em vez de "98999-0001, 3222-0001"
--      numa unica coluna, cada telefone vira uma linha.
-- PK composta: (paciente_id, telefone)
-- -------------------------------------------------------------
CREATE TABLE paciente_telefones (
    paciente_id  INT         NOT NULL REFERENCES pacientes(id) ON DELETE CASCADE,
    telefone     VARCHAR(15) NOT NULL CHECK (telefone ~ '^[0-9]{10,11}$'),
    tipo         VARCHAR(12) NOT NULL DEFAULT 'CELULAR'
                 CHECK (tipo IN ('CELULAR', 'RESIDENCIAL', 'TRABALHO')),
    PRIMARY KEY (paciente_id, telefone)
);

-- -------------------------------------------------------------
-- MEDICOS   (N medicos : 1 especialidade)
-- -------------------------------------------------------------
CREATE TABLE medicos (
    id                SERIAL        PRIMARY KEY,
    nome              VARCHAR(120)  NOT NULL,
    crm               VARCHAR(15)   NOT NULL UNIQUE,
    especialidade_id  INT           NOT NULL REFERENCES especialidades(id),
    valor_consulta    NUMERIC(10,2) NOT NULL CHECK (valor_consulta > 0)
);

-- -------------------------------------------------------------
-- CONSULTAS   (resolve o N:N entre pacientes e medicos)
-- "valor" guarda o preco COBRADO naquela consulta. Nao e redundancia
-- com medicos.valor_consulta: o preco do medico muda com o tempo e a
-- consulta precisa guardar o valor historico (fato da consulta).
-- -------------------------------------------------------------
CREATE TABLE consultas (
    id           SERIAL        PRIMARY KEY,
    paciente_id  INT           NOT NULL REFERENCES pacientes(id),
    medico_id    INT           NOT NULL REFERENCES medicos(id),
    data_hora    TIMESTAMP     NOT NULL,
    status       VARCHAR(12)   NOT NULL DEFAULT 'AGENDADA'
                 CHECK (status IN ('AGENDADA', 'REALIZADA', 'CANCELADA')),
    valor        NUMERIC(10,2) NOT NULL CHECK (valor >= 0)
);

-- Um medico nao atende dois pacientes no mesmo horario
CREATE UNIQUE INDEX uq_consulta_medico_horario
    ON consultas (medico_id, data_hora) WHERE status <> 'CANCELADA';

-- -------------------------------------------------------------
-- PRONTUARIOS   (1 consulta : 0..1 prontuario)
-- Relacionamento 1:1 -> a PK e TAMBEM a FK para consultas.
-- -------------------------------------------------------------
CREATE TABLE prontuarios (
    consulta_id  INT       PRIMARY KEY REFERENCES consultas(id),
    diagnostico  TEXT      NOT NULL,
    observacoes  TEXT,
    criado_em    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------------
-- MEDICAMENTOS
-- -------------------------------------------------------------
CREATE TABLE medicamentos (
    id               SERIAL       PRIMARY KEY,
    nome             VARCHAR(80)  NOT NULL,
    principio_ativo  VARCHAR(80)  NOT NULL,
    apresentacao     VARCHAR(40)  NOT NULL,          -- ex.: "50 mg comprimido"
    UNIQUE (nome, apresentacao)
);

-- -------------------------------------------------------------
-- PRESCRICOES   (tabela ASSOCIATIVA do N:N consultas x medicamentos)
-- Uma consulta prescreve varios medicamentos e um medicamento
-- aparece em varias consultas.
-- PK composta = juncao das duas FKs.
-- -------------------------------------------------------------
CREATE TABLE prescricoes (
    consulta_id     INT          NOT NULL REFERENCES consultas(id),
    medicamento_id  INT          NOT NULL REFERENCES medicamentos(id),
    posologia       VARCHAR(120) NOT NULL,          -- ex.: "1 comprimido a cada 12h"
    duracao_dias    INT          NOT NULL CHECK (duracao_dias > 0),
    PRIMARY KEY (consulta_id, medicamento_id)
);

-- -------------------------------------------------------------
-- PAGAMENTOS   (1 consulta : 0..1 pagamento)
-- -------------------------------------------------------------
CREATE TABLE pagamentos (
    id           SERIAL        PRIMARY KEY,
    consulta_id  INT           NOT NULL UNIQUE REFERENCES consultas(id),
    valor        NUMERIC(10,2) NOT NULL CHECK (valor > 0),
    forma        VARCHAR(10)   NOT NULL
                 CHECK (forma IN ('PIX', 'CARTAO', 'DINHEIRO', 'CONVENIO')),
    pago_em      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
