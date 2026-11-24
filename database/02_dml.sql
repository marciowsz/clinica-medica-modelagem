-- =============================================================
-- Clinica Medica - DADOS DE TESTE (INSERT INTO)
-- Rodar depois do 01_ddl.sql:
--   psql -d clinica_medica -f database/02_dml.sql
-- Os INSERTs usam as FKs entre tabelas relacionadas; se alguma
-- referencia nao existisse, o PostgreSQL recusaria a linha.
-- =============================================================

BEGIN;

INSERT INTO especialidades (id, nome, descricao) VALUES
    (1, 'Cardiologia', 'Doencas do coracao e do sistema circulatorio'),
    (2, 'Pediatria',   'Saude de criancas e adolescentes');

INSERT INTO pacientes (id, nome, cpf, data_nascimento, email) VALUES
    (1, 'Ana Souza',     '12345678901', '1990-04-12', 'ana@email.com'),
    (2, 'Bruno Almeida', '23456789012', '1985-09-30', 'bruno@email.com'),
    (3, 'Carla Mendes',  '34567890123', '2015-01-05', NULL);

-- FK paciente_telefones.paciente_id -> pacientes.id
INSERT INTO paciente_telefones (paciente_id, telefone, tipo) VALUES
    (1, '98999990001', 'CELULAR'),
    (1, '9832220001',  'RESIDENCIAL'),
    (2, '98999990002', 'CELULAR'),
    (3, '98999990003', 'CELULAR');

-- FK medicos.especialidade_id -> especialidades.id
INSERT INTO medicos (id, nome, crm, especialidade_id, valor_consulta) VALUES
    (1, 'Dr. Paulo Lima',      '10234-MA', 1, 350.00),
    (2, 'Dra. Fernanda Rocha', '20456-MA', 2, 250.00);

-- FKs consultas.paciente_id e consultas.medico_id
INSERT INTO consultas (id, paciente_id, medico_id, data_hora, status, valor) VALUES
    (1, 1, 1, '2026-12-01 09:00', 'REALIZADA', 350.00),
    (2, 2, 1, '2026-12-01 09:30', 'AGENDADA',  350.00),
    (3, 3, 2, '2026-12-01 10:00', 'REALIZADA', 250.00);

-- FK prontuarios.consulta_id (PK = FK, relacionamento 1:1)
INSERT INTO prontuarios (consulta_id, diagnostico, observacoes) VALUES
    (1, 'Hipertensao arterial leve', 'Retorno em 30 dias'),
    (3, 'Amigdalite bacteriana',     'Repouso e hidratacao');

INSERT INTO medicamentos (id, nome, principio_ativo, apresentacao) VALUES
    (1, 'Losartana',   'Losartana potassica', '50 mg comprimido'),
    (2, 'Amoxicilina', 'Amoxicilina',         '250 mg/5 ml suspensao'),
    (3, 'Dipirona',    'Dipirona monoidratada','500 mg/ml gotas');

-- Tabela associativa N:N (consultas x medicamentos)
INSERT INTO prescricoes (consulta_id, medicamento_id, posologia, duracao_dias) VALUES
    (1, 1, '1 comprimido pela manha',          30),
    (3, 2, '5 ml a cada 8 horas',              10),
    (3, 3, '15 gotas se febre, ate 4x ao dia',  5);

INSERT INTO pagamentos (consulta_id, valor, forma) VALUES
    (1, 350.00, 'PIX'),
    (3, 250.00, 'CARTAO');

COMMIT;

-- Ajusta as sequences depois dos INSERTs com id explicito
SELECT setval('especialidades_id_seq', (SELECT MAX(id) FROM especialidades));
SELECT setval('pacientes_id_seq',      (SELECT MAX(id) FROM pacientes));
SELECT setval('medicos_id_seq',        (SELECT MAX(id) FROM medicos));
SELECT setval('consultas_id_seq',      (SELECT MAX(id) FROM consultas));
SELECT setval('medicamentos_id_seq',   (SELECT MAX(id) FROM medicamentos));

-- =============================================================
-- CONSULTAS QUE COMPROVAM OS RELACIONAMENTOS (JOIN pelas FKs)
-- =============================================================

-- Consulta + paciente + medico + especialidade
SELECT c.id, p.nome AS paciente, m.nome AS medico, e.nome AS especialidade,
       c.data_hora, c.status
FROM consultas c
JOIN pacientes      p ON p.id = c.paciente_id
JOIN medicos        m ON m.id = c.medico_id
JOIN especialidades e ON e.id = m.especialidade_id
ORDER BY c.id;

-- Receita da consulta 3 (N:N via prescricoes)
SELECT p.nome AS paciente, md.nome AS medicamento, md.apresentacao, pr.posologia, pr.duracao_dias
FROM prescricoes pr
JOIN consultas    c  ON c.id  = pr.consulta_id
JOIN pacientes    p  ON p.id  = c.paciente_id
JOIN medicamentos md ON md.id = pr.medicamento_id
WHERE pr.consulta_id = 3;

-- Telefones de cada paciente (1FN: uma linha por telefone)
SELECT p.nome, t.tipo, t.telefone
FROM pacientes p
JOIN paciente_telefones t ON t.paciente_id = p.id
ORDER BY p.nome, t.tipo;
