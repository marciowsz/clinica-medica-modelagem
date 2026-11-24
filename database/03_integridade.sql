-- =============================================================
-- BONUS - Demonstracao de violacao de integridade
-- Rodar depois do 02_dml.sql:
--   psql -d clinica_medica -v ON_ERROR_STOP=1 -f database/03_integridade.sql
--
-- Cada bloco tenta um INSERT INVALIDO. O PostgreSQL recusa, o erro
-- e capturado e a mensagem real do banco e exibida (NOTICE).
-- Se o banco ACEITASSE o dado, o script falharia (RAISE EXCEPTION).
-- Para ver o erro "cru", rode so o INSERT de dentro do bloco no psql.
-- =============================================================

-- 1. FK inexistente: consulta para um paciente que nao existe
DO $$
BEGIN
    INSERT INTO consultas (paciente_id, medico_id, data_hora, valor)
    VALUES (999, 1, '2026-12-05 08:00', 350.00);
    RAISE EXCEPTION 'FALHOU: aceitou paciente_id inexistente';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE '[FK] recusado -> %', SQLERRM;
END $$;

-- 2. FK inexistente: prescricao de um medicamento que nao existe
DO $$
BEGIN
    INSERT INTO prescricoes (consulta_id, medicamento_id, posologia, duracao_dias)
    VALUES (1, 999, '1 comprimido', 5);
    RAISE EXCEPTION 'FALHOU: aceitou medicamento_id inexistente';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE '[FK] recusado -> %', SQLERRM;
END $$;

-- 3. PK duplicada: paciente com id que ja existe
DO $$
BEGIN
    INSERT INTO pacientes (id, nome, cpf, data_nascimento)
    VALUES (1, 'Paciente Repetido', '99999999999', '2000-01-01');
    RAISE EXCEPTION 'FALHOU: aceitou PK duplicada em pacientes';
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE '[PK] recusado -> %', SQLERRM;
END $$;

-- 4. PK composta duplicada: mesmo medicamento duas vezes na mesma consulta
DO $$
BEGIN
    INSERT INTO prescricoes (consulta_id, medicamento_id, posologia, duracao_dias)
    VALUES (3, 2, '10 ml a cada 12 horas', 7);
    RAISE EXCEPTION 'FALHOU: aceitou PK composta duplicada em prescricoes';
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE '[PK composta] recusado -> %', SQLERRM;
END $$;

-- 5. PK = FK (1:1): segundo prontuario para a mesma consulta
DO $$
BEGIN
    INSERT INTO prontuarios (consulta_id, diagnostico) VALUES (1, 'Outro diagnostico');
    RAISE EXCEPTION 'FALHOU: aceitou dois prontuarios para a mesma consulta';
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE '[1:1] recusado -> %', SQLERRM;
END $$;

-- 6. Exclusao que deixaria registros orfaos: apagar medico com consultas
DO $$
BEGIN
    DELETE FROM medicos WHERE id = 1;
    RAISE EXCEPTION 'FALHOU: apagou medico com consultas (orfaos)';
EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE '[FK - DELETE] recusado -> %', SQLERRM;
END $$;

-- 7. Conferencia final: nada foi gravado pelos testes acima
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM consultas)   <> 3
       OR (SELECT COUNT(*) FROM prescricoes) <> 3
       OR (SELECT COUNT(*) FROM prontuarios) <> 2
       OR (SELECT COUNT(*) FROM medicos)     <> 2 THEN
        RAISE EXCEPTION 'FALHOU: dados foram alterados indevidamente';
    END IF;
    RAISE NOTICE '[OK] integridade preservada: nenhum dado invalido foi gravado';
END $$;
