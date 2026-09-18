/*
 * ============================================================
 * SISTEMA DE TRANSPORTE ESCOLAR
 * ============================================================
 *
 * Estratégia de criação das tabelas:
 *
 * 1. Primeiro criamos as tabelas que não possuem Foreign Keys.
 * 2. Depois criamos as tabelas que dependem das anteriores.
 * 3. Seguimos a ordem das dependências até chegar às tabelas
 *    que possuem vários relacionamentos.
 *
 * Isso é importante porque uma Foreign Key precisa referenciar
 * uma tabela que já exista.
 *
 * GENERATED ALWAYS AS IDENTITY:
 *
 *     id INT GENERATED ALWAYS AS IDENTITY
 *
 * Faz com que o PostgreSQL gere automaticamente o valor da
 * coluna utilizando um mecanismo interno de sequência.
 */


/* ============================================================
 * RESPONSAVEL
 * ============================================================
 *
 * Representa os responsáveis legais pelos alunos.
 *
 * Esta tabela não possui Foreign Keys, portanto pode ser
 * criada independentemente das outras tabelas.
 *
 * Restrições:
 *
 * PRIMARY KEY
 *     Identifica exclusivamente cada responsável.
 *
 * UNIQUE
 *     Impede CPF e e-mail duplicados.
 *
 * NOT NULL
 *     Obriga o preenchimento do atributo.
 */

CREATE TABLE IF NOT EXISTS responsavel (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cpf CHAR(11) NOT NULL UNIQUE,
    telefone CHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    endereco VARCHAR(150) NOT NULL
);


/* ============================================================
 * PONTO_EMBARQUE
 * ============================================================
 *
 * Representa os locais utilizados pelos alunos para embarque
 * no transporte escolar.
 *
 * Esta tabela também não possui Foreign Keys.
 *
 * latitude e longitude utilizam DECIMAL para armazenar as
 * coordenadas geográficas.
 */

CREATE TABLE IF NOT EXISTS ponto_embarque (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descricao TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL
);


/* ============================================================
 * MOTORISTA
 * ============================================================
 *
 * Representa os motoristas responsáveis pela condução dos
 * veículos.
 *
 * CPF e CNH recebem UNIQUE porque cada documento deve
 * pertencer a apenas um motorista.
 */

CREATE TABLE IF NOT EXISTS motorista (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    cnh VARCHAR(20) NOT NULL UNIQUE,
    telefone CHAR(15) NOT NULL
);


/* ============================================================
 * VEICULO
 * ============================================================
 *
 * Representa os veículos utilizados no transporte escolar.
 *
 * A constraint:
 *
 *     CHECK (capacidade > 0)
 *
 * garante a integridade do domínio da coluna capacidade.
 *
 * Dessa forma, o PostgreSQL rejeitará valores iguais ou
 * menores que zero.
 */

CREATE TABLE IF NOT EXISTS veiculo (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    placa VARCHAR(8) NOT NULL,
    modelo VARCHAR(50) NOT NULL,

    capacidade INT NOT NULL
        CHECK (capacidade > 0)
);


/* ============================================================
 * ALUNO
 * ============================================================
 *
 * Representa os alunos atendidos pelo sistema.
 *
 * Esta tabela possui duas Foreign Keys.
 *
 *
 * RELACIONAMENTO RESPONSAVEL -> ALUNO
 *
 * Um responsável pode possuir vários alunos associados:
 *
 *     responsavel 1:N aluno
 *
 * A FK fica em aluno porque aluno representa o lado N.
 *
 *
 * RELACIONAMENTO PONTO_EMBARQUE -> ALUNO
 *
 * Um ponto de embarque pode atender vários alunos:
 *
 *     ponto_embarque 1:N aluno
 *
 * Cada aluno, por sua vez, possui somente um
 * id_ponto_embarque.
 *
 *
 * ON DELETE RESTRICT:
 *
 * Impede que o registro pai seja excluído enquanto existirem
 * registros filhos apontando para ele.
 */

CREATE TABLE IF NOT EXISTS aluno (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    data_nascimento DATE NOT NULL,
    serie VARCHAR(20) NOT NULL,

    id_responsavel INT
        REFERENCES responsavel(id)
        ON DELETE RESTRICT,

    id_ponto_embarque INT NOT NULL
        REFERENCES ponto_embarque(id)
        ON DELETE RESTRICT
);


/* ============================================================
 * ROTA
 * ============================================================
 *
 * Representa o planejamento de uma rota de transporte.
 *
 * Cada rota possui:
 *
 * - um nome;
 * - um turno;
 * - horário planejado de partida;
 * - horário planejado de chegada;
 * - um veículo;
 * - um motorista.
 *
 * Portanto:
 *
 *     veiculo 1:N rota
 *     motorista 1:N rota
 */

CREATE TABLE IF NOT EXISTS rota (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_rota VARCHAR(100) NOT NULL,
    turno VARCHAR(100) NOT NULL,
    horario_partida TIME NOT NULL,
    horario_chegada TIME NOT NULL,

    id_veiculo INT NOT NULL
        REFERENCES veiculo(id),

    id_motorista INT NOT NULL
        REFERENCES motorista(id)
);


/* ============================================================
 * VIAGEM
 * ============================================================
 *
 * Representa uma execução concreta de uma rota.
 *
 * A diferença entre rota e viagem é importante:
 *
 * ROTA:
 *     representa o planejamento.
 *
 * VIAGEM:
 *     representa uma execução daquele planejamento em uma
 *     determinada data.
 *
 * Exemplo:
 *
 *     Rota:
 *         "Rota Norte"
 *
 *     Viagem:
 *         Execução da Rota Norte em 17/09/2026.
 *
 * TIMESTAMP armazena data e hora simultaneamente.
 *
 * Cada viagem referencia:
 *
 * - uma rota;
 * - um motorista;
 * - um veículo.
 */

CREATE TABLE IF NOT EXISTS viagem (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    data_viagem DATE NOT NULL,
    horario_inicio TIMESTAMP NOT NULL,
    horario_fim TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,

    id_rota INT NOT NULL
        REFERENCES rota(id),

    id_motorista INT NOT NULL
        REFERENCES motorista(id),

    id_veiculo INT NOT NULL
        REFERENCES veiculo(id)
);


/* ============================================================
 * ROTA_PONTO
 * ============================================================
 *
 * Representa o relacionamento entre as rotas e os pontos de
 * embarque.
 *
 * Uma rota pode possuir vários pontos de embarque.
 *
 * Um ponto de embarque pode aparecer em várias rotas.
 *
 * Portanto:
 *
 *     rota N:N ponto_embarque
 *
 * Um relacionamento N:N é representado através de uma
 * tabela associativa.
 *
 *
 * PRIMARY KEY COMPOSTA
 *
 * A chave:
 *
 *     PRIMARY KEY (id_rota, id_ponto_embarque)
 *
 * impede que o mesmo ponto seja associado duas vezes à mesma
 * rota.
 *
 *
 * ordem_parada:
 *
 * Indica a ordem em que os pontos devem ser visitados.
 *
 * Exemplo:
 *
 *     1 -> Praça Central
 *     2 -> Escola Municipal Primavera
 *     3 -> Terminal Rodoviário
 */

CREATE TABLE IF NOT EXISTS rota_ponto (
    id_rota INT NOT NULL
        REFERENCES rota(id),

    id_ponto_embarque INT NOT NULL
        REFERENCES ponto_embarque(id),

    ordem_parada INT NOT NULL,
    horario_estimado TIME NOT NULL,

    CONSTRAINT rota_ponto_pk
        PRIMARY KEY (id_rota, id_ponto_embarque)
);


/* ============================================================
 * REGISTRO_PRESENCA
 * ============================================================
 *
 * Representa o registro da presença de um aluno durante uma
 * viagem.
 *
 * Cada registro informa:
 *
 * - quando ocorreu;
 * - status da presença;
 * - qual viagem;
 * - qual aluno;
 * - qual ponto de embarque.
 */

CREATE TABLE IF NOT EXISTS registro_presenca (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    data_hora TIMESTAMP NOT NULL,
    status_presenca VARCHAR(20) NOT NULL,

    id_viagem INT NOT NULL
        REFERENCES viagem(id),

    id_aluno INT NOT NULL
        REFERENCES aluno(id),

    id_ponto_embarque INT NOT NULL
        REFERENCES ponto_embarque(id)
);


/* ============================================================
 * POPULACAO INICIAL DAS TABELAS
 * ============================================================
 *
 * Os INSERTs precisam respeitar a ordem das dependências.
 *
 * Primeiro inserimos dados nas tabelas independentes.
 * Depois inserimos nas tabelas que possuem Foreign Keys.
 */


/* ============================================================
 * RESPONSAVEL
 * ============================================================
 *
 * Não informamos o id porque ele é gerado automaticamente
 * através de GENERATED ALWAYS AS IDENTITY.
 */

INSERT INTO responsavel (
    cpf,
    telefone,
    email,
    endereco
)
VALUES
    (
        '12345678901',
        '94991234567',
        'carlos.silva@email.com',
        'Rua das Flores, 120'
    ),
    (
        '23456789012',
        '94992345678',
        'ana.souza@email.com',
        'Avenida Brasil, 450'
    ),
    (
        '34567890123',
        '94993456789',
        'marcos.oliveira@email.com',
        'Rua Pará, 88'
    ),
    (
        '45678901234',
        '94994567890',
        'juliana.costa@email.com',
        'Rua Amazonas, 305'
    ),
    (
        '56789012345',
        '94995678901',
        'roberto.almeida@email.com',
        'Avenida Liberdade, 740'
    );


/* ============================================================
 * PONTO_EMBARQUE
 * ============================================================
 */

INSERT INTO ponto_embarque (
    descricao,
    latitude,
    longitude
)
VALUES
    (
        'Praça Central',
        -6.06741900,
        -49.90222100
    ),
    (
        'Escola Municipal Primavera',
        -6.07235000,
        -49.89561000
    ),
    (
        'Terminal Rodoviário',
        -6.06324000,
        -49.90783000
    ),
    (
        'Praça do Bairro Cidade Nova',
        -6.07548000,
        -49.91326000
    ),
    (
        'Avenida dos Ipês',
        -6.05891000,
        -49.89932000
    );


/* ============================================================
 * MOTORISTA
 * ============================================================
 */

INSERT INTO motorista (
    nome,
    cpf,
    cnh,
    telefone
)
VALUES
    (
        'João Ferreira',
        '11122233344',
        'CNH001234567',
        '94991112222'
    ),
    (
        'Maria Oliveira',
        '22233344455',
        'CNH002345678',
        '94992223333'
    ),
    (
        'Paulo Mendes',
        '33344455566',
        'CNH003456789',
        '94993334444'
    );


/* ============================================================
 * VEICULO
 * ============================================================
 *
 * Todos os valores de capacidade são maiores que zero,
 * respeitando:
 *
 *     CHECK (capacidade > 0)
 */

INSERT INTO veiculo (
    placa,
    modelo,
    capacidade
)
VALUES
    (
        'ABC1D23',
        'Mercedes-Benz Sprinter',
        20
    ),
    (
        'DEF4G56',
        'Volkswagen Escolarbus',
        32
    ),
    (
        'GHI7J89',
        'Iveco Daily Minibus',
        18
    );


/* ============================================================
 * ALUNO
 * ============================================================
 *
 * Os valores de id_responsavel e id_ponto_embarque são
 * Foreign Keys.
 *
 * Assumindo que os IDs foram gerados a partir de 1:
 *
 * responsavel:
 *     1 até 5
 *
 * ponto_embarque:
 *     1 até 5
 */

INSERT INTO aluno (
    nome,
    data_nascimento,
    serie,
    id_responsavel,
    id_ponto_embarque
)
VALUES
    ('Gabriel Silva',  '2014-03-12', '6º Ano', 1, 1),
    ('Mariana Silva',  '2016-07-21', '4º Ano', 1, 1),
    ('Lucas Souza',    '2013-10-05', '7º Ano', 2, 2),
    ('Sofia Souza',    '2015-02-18', '5º Ano', 2, 3),
    ('Pedro Oliveira', '2012-11-30', '8º Ano', 3, 2),
    ('Beatriz Costa',  '2014-05-16', '6º Ano', 4, 4),
    ('Rafael Almeida', '2013-08-09', '7º Ano', 5, 5),
    ('Laura Almeida',  '2016-01-27', '4º Ano', 5, 5);


/* ============================================================
 * ROTA
 * ============================================================
 *
 * Cada registro referencia:
 *
 *     id_veiculo
 *     id_motorista
 */

INSERT INTO rota (
    nome_rota,
    turno,
    horario_partida,
    horario_chegada,
    id_veiculo,
    id_motorista
)
VALUES
    (
        'Rota Norte',
        'Manhã',
        '06:00:00',
        '07:20:00',
        1,
        1
    ),
    (
        'Rota Sul',
        'Manhã',
        '06:15:00',
        '07:30:00',
        2,
        2
    ),
    (
        'Rota Centro',
        'Tarde',
        '12:30:00',
        '13:45:00',
        3,
        3
    );


/* ============================================================
 * ROTA_PONTO
 * ============================================================
 *
 * Aqui relacionamos as rotas aos seus respectivos pontos.
 *
 * Estrutura:
 *
 * (id_rota, id_ponto_embarque, ordem_parada, horario_estimado)
 */

INSERT INTO rota_ponto (
    id_rota,
    id_ponto_embarque,
    ordem_parada,
    horario_estimado
)
VALUES
    /* Rota Norte */
    (1, 1, 1, '06:10:00'),
    (1, 2, 2, '06:30:00'),
    (1, 3, 3, '06:50:00'),

    /* Rota Sul */
    (2, 2, 1, '06:25:00'),
    (2, 4, 2, '06:50:00'),

    /* Rota Centro */
    (3, 3, 1, '12:40:00'),
    (3, 5, 2, '13:00:00');


/* ============================================================
 * VIAGEM
 * ============================================================
 *
 * Cada linha representa uma execução concreta de uma rota.
 *
 * Exemplo:
 *
 * id_rota = 1
 *
 * significa que aquela viagem é uma execução da Rota Norte.
 */

INSERT INTO viagem (
    data_viagem,
    horario_inicio,
    horario_fim,
    status,
    id_rota,
    id_motorista,
    id_veiculo
)
VALUES
    (
        '2026-09-17',
        '2026-09-17 06:00:00',
        '2026-09-17 07:18:00',
        'FINALIZADA',
        1,
        1,
        1
    ),
    (
        '2026-09-17',
        '2026-09-17 06:15:00',
        '2026-09-17 07:27:00',
        'FINALIZADA',
        2,
        2,
        2
    ),
    (
        '2026-09-17',
        '2026-09-17 12:30:00',
        '2026-09-17 13:42:00',
        'FINALIZADA',
        3,
        3,
        3
    ),
    (
        '2026-09-18',
        '2026-09-18 06:00:00',
        '2026-09-18 07:21:00',
        'FINALIZADA',
        1,
        1,
        1
    );


/* ============================================================
 * REGISTRO_PRESENCA
 * ============================================================
 *
 * Registra a situação dos alunos em cada viagem.
 *
 * Estrutura:
 *
 * (
 *     data_hora,
 *     status_presenca,
 *     id_viagem,
 *     id_aluno,
 *     id_ponto_embarque
 * )
 */

INSERT INTO registro_presenca (
    data_hora,
    status_presenca,
    id_viagem,
    id_aluno,
    id_ponto_embarque
)
VALUES
    /* Viagem 1 - Rota Norte */
    ('2026-09-17 06:09:15', 'PRESENTE', 1, 1, 1),
    ('2026-09-17 06:09:42', 'PRESENTE', 1, 2, 1),
    ('2026-09-17 06:29:31', 'PRESENTE', 1, 3, 2),
    ('2026-09-17 06:49:05', 'AUSENTE',  1, 4, 3),

    /* Viagem 2 - Rota Sul */
    ('2026-09-17 06:24:20', 'PRESENTE', 2, 5, 2),
    ('2026-09-17 06:49:37', 'PRESENTE', 2, 6, 4),

    /* Viagem 3 - Rota Centro */
    ('2026-09-17 12:59:10', 'PRESENTE', 3, 7, 5),
    ('2026-09-17 12:59:35', 'PRESENTE', 3, 8, 5),

    /* Viagem 4 - Rota Norte */
    ('2026-09-18 06:09:12', 'PRESENTE', 4, 1, 1),
    ('2026-09-18 06:09:39', 'AUSENTE',  4, 2, 1),
    ('2026-09-18 06:30:03', 'PRESENTE', 4, 3, 2),
    ('2026-09-18 06:50:11', 'PRESENTE', 4, 4, 3);


/* ============================================================
 * CONSULTAS DAS TABELAS
 * ============================================================
 *
 * SELECT consulta registros armazenados no banco.
 *
 * JOIN permite combinar informações provenientes de tabelas
 * diferentes através dos seus relacionamentos.
 */


/*
 * 1. Quem são os responsáveis dos alunos?
 *
 * LEFT JOIN:
 *
 * Retorna todos os registros da tabela posicionada à esquerda
 * (aluno), mesmo que não exista um responsável correspondente.
 *
 * A condição:
 *
 *     aluno.id_responsavel = responsavel.id
 *
 * define como os registros das duas tabelas devem ser
 * relacionados.
 */

SELECT *
FROM aluno
LEFT JOIN responsavel
    ON aluno.id_responsavel = responsavel.id;


/*
 * 2. Quais são as rotas de cada viagem?
 *
 * viagem.id_rota é a Foreign Key que aponta para rota.id.
 */

SELECT *
FROM viagem
LEFT JOIN rota
    ON viagem.id_rota = rota.id;


/*
 * 3. Quem são os alunos presentes?
 *
 * Primeiro relacionamos aluno e registro_presenca.
 *
 * Depois utilizamos WHERE para manter somente registros cujo
 * status seja PRESENTE.
 *
 * Apesar de utilizarmos LEFT JOIN, a condição no WHERE exige
 * que exista um registro_presenca com status PRESENTE.
 */

SELECT *
FROM aluno
LEFT JOIN registro_presenca
    ON aluno.id = registro_presenca.id_aluno
WHERE registro_presenca.status_presenca = 'PRESENTE';


/* ============================================================
 * ATUALIZACAO DAS TABELAS
 * ============================================================
 *
 * UPDATE modifica registros que já existem.
 *
 * Estrutura geral:
 *
 *     UPDATE tabela
 *     SET coluna = novo_valor
 *     WHERE condição;
 *
 * O WHERE determina quais registros serão modificados.
 */


/*
 * Atualiza somente o responsável cujo id seja igual a 1.
 */

UPDATE responsavel
SET email = 'carlos.decornos.silva@gmail.com'
WHERE id = 1;


/*
 * Atualiza somente o motorista cujo id seja igual a 1.
 *
 * Se o WHERE fosse removido, TODOS os motoristas teriam
 * o nome alterado.
 */

UPDATE motorista
SET nome = 'Sir. Perv El Tido'
WHERE id = 1;


/* ============================================================
 * DELECAO DAS TABELAS
 * ============================================================
 *
 * DROP TABLE remove a própria estrutura da tabela.
 *
 * Não confundir com:
 *
 *     DELETE FROM tabela;
 *
 * DELETE remove registros.
 *
 * DROP TABLE remove a tabela.
 *
 *
 * CASCADE
 *
 * CASCADE também remove dependências relacionadas ao objeto
 * que está sendo excluído.
 *
 * Por isso, deve ser utilizado com cuidado.
 *
 * ATENÇÃO:
 *
 * Os comandos abaixo DESTROEM as tabelas criadas anteriormente.
 * Eles normalmente devem ser utilizados apenas quando você
 * realmente desejar remover o banco de testes.
 */

DROP TABLE responsavel CASCADE;

DROP TABLE ponto_embarque CASCADE;

DROP TABLE aluno CASCADE;

DROP TABLE motorista CASCADE;

DROP TABLE veiculo CASCADE;

DROP TABLE rota CASCADE;

DROP TABLE rota_ponto CASCADE;

DROP TABLE viagem CASCADE;

DROP TABLE registro_presenca CASCADE;
/*
 * ============================================================
 * SISTEMA DE TRANSPORTE ESCOLAR
 * ============================================================
 *
 * Estratégia de criação das tabelas:
 *
 * 1. Primeiro criamos as tabelas que não possuem Foreign Keys.
 * 2. Depois criamos as tabelas que dependem das anteriores.
 * 3. Seguimos a ordem das dependências até chegar às tabelas
 *    que possuem vários relacionamentos.
 *
 * Isso é importante porque uma Foreign Key precisa referenciar
 * uma tabela que já exista.
 *
 * GENERATED ALWAYS AS IDENTITY:
 *
 *     id INT GENERATED ALWAYS AS IDENTITY
 *
 * Faz com que o PostgreSQL gere automaticamente o valor da
 * coluna utilizando um mecanismo interno de sequência.
 */


/* ============================================================
 * RESPONSAVEL
 * ============================================================
 *
 * Representa os responsáveis legais pelos alunos.
 *
 * Esta tabela não possui Foreign Keys, portanto pode ser
 * criada independentemente das outras tabelas.
 *
 * Restrições:
 *
 * PRIMARY KEY
 *     Identifica exclusivamente cada responsável.
 *
 * UNIQUE
 *     Impede CPF e e-mail duplicados.
 *
 * NOT NULL
 *     Obriga o preenchimento do atributo.
 */

CREATE TABLE IF NOT EXISTS responsavel (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cpf CHAR(11) NOT NULL UNIQUE,
    telefone CHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    endereco VARCHAR(150) NOT NULL
);

/* ============================================================
 * PONTO_EMBARQUE
 * ============================================================
 *
 * Representa os locais utilizados pelos alunos para embarque
 * no transporte escolar.
 *
 * Esta tabela também não possui Foreign Keys.
 *
 * latitude e longitude utilizam DECIMAL para armazenar as
 * coordenadas geográficas.
 */

CREATE TABLE IF NOT EXISTS ponto_embarque (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descricao TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL
);

/* ============================================================
 * MOTORISTA
 * ============================================================
 *
 * Representa os motoristas responsáveis pela condução dos
 * veículos.
 *
 * CPF e CNH recebem UNIQUE porque cada documento deve
 * pertencer a apenas um motorista.
 */

CREATE TABLE IF NOT EXISTS motorista (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    cnh VARCHAR(20) NOT NULL UNIQUE,
    telefone CHAR(15) NOT NULL
);

/* ============================================================
 * VEICULO
 * ============================================================
 *
 * Representa os veículos utilizados no transporte escolar.
 *
 * A constraint:
 *
 *     CHECK (capacidade > 0)
 *
 * garante a integridade do domínio da coluna capacidade.
 *
 * Dessa forma, o PostgreSQL rejeitará valores iguais ou
 * menores que zero.
 */

CREATE TABLE IF NOT EXISTS veiculo (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    placa VARCHAR(8) NOT NULL,
    modelo VARCHAR(50) NOT NULL,

    capacidade INT NOT NULL
        CHECK (capacidade > 0)
);

/* ============================================================
 * ALUNO
 * ============================================================
 *
 * Representa os alunos atendidos pelo sistema.
 *
 * Esta tabela possui duas Foreign Keys.
 *
 *
 * RELACIONAMENTO RESPONSAVEL -> ALUNO
 *
 * Um responsável pode possuir vários alunos associados:
 *
 *     responsavel 1:N aluno
 *
 * A FK fica em aluno porque aluno representa o lado N.
 *
 *
 * RELACIONAMENTO PONTO_EMBARQUE -> ALUNO
 *
 * Um ponto de embarque pode atender vários alunos:
 *
 *     ponto_embarque 1:N aluno
 *
 * Cada aluno, por sua vez, possui somente um
 * id_ponto_embarque.
 *
 *
 * ON DELETE RESTRICT:
 *
 * Impede que o registro pai seja excluído enquanto existirem
 * registros filhos apontando para ele.
 */

CREATE TABLE IF NOT EXISTS aluno (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    data_nascimento DATE NOT NULL,
    serie VARCHAR(20) NOT NULL,

    id_responsavel INT
        REFERENCES responsavel(id)
        ON
DELETE
	RESTRICT,
	id_ponto_embarque INT NOT NULL
        REFERENCES ponto_embarque(id)
        ON
	DELETE
		RESTRICT
);

/* ============================================================
 * ROTA
 * ============================================================
 *
 * Representa o planejamento de uma rota de transporte.
 *
 * Cada rota possui:
 *
 * - um nome;
 * - um turno;
 * - horário planejado de partida;
 * - horário planejado de chegada;
 * - um veículo;
 * - um motorista.
 *
 * Portanto:
 *
 *     veiculo 1:N rota
 *     motorista 1:N rota
 */

CREATE TABLE IF NOT EXISTS rota (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_rota VARCHAR(100) NOT NULL,
    turno VARCHAR(100) NOT NULL,
    horario_partida TIME NOT NULL,
    horario_chegada TIME NOT NULL,

    id_veiculo INT NOT NULL
        REFERENCES veiculo(id),

    id_motorista INT NOT NULL
        REFERENCES motorista(id)
);

/* ============================================================
 * VIAGEM
 * ============================================================
 *
 * Representa uma execução concreta de uma rota.
 *
 * A diferença entre rota e viagem é importante:
 *
 * ROTA:
 *     representa o planejamento.
 *
 * VIAGEM:
 *     representa uma execução daquele planejamento em uma
 *     determinada data.
 *
 * Exemplo:
 *
 *     Rota:
 *         "Rota Norte"
 *
 *     Viagem:
 *         Execução da Rota Norte em 17/09/2026.
 *
 * TIMESTAMP armazena data e hora simultaneamente.
 *
 * Cada viagem referencia:
 *
 * - uma rota;
 * - um motorista;
 * - um veículo.
 */

CREATE TABLE IF NOT EXISTS viagem (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    data_viagem DATE NOT NULL,
    horario_inicio TIMESTAMP NOT NULL,
    horario_fim TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,

    id_rota INT NOT NULL
        REFERENCES rota(id),

    id_motorista INT NOT NULL
        REFERENCES motorista(id),

    id_veiculo INT NOT NULL
        REFERENCES veiculo(id)
);

/* ============================================================
 * ROTA_PONTO
 * ============================================================
 *
 * Representa o relacionamento entre as rotas e os pontos de
 * embarque.
 *
 * Uma rota pode possuir vários pontos de embarque.
 *
 * Um ponto de embarque pode aparecer em várias rotas.
 *
 * Portanto:
 *
 *     rota N:N ponto_embarque
 *
 * Um relacionamento N:N é representado através de uma
 * tabela associativa.
 *
 *
 * PRIMARY KEY COMPOSTA
 *
 * A chave:
 *
 *     PRIMARY KEY (id_rota, id_ponto_embarque)
 *
 * impede que o mesmo ponto seja associado duas vezes à mesma
 * rota.
 *
 *
 * ordem_parada:
 *
 * Indica a ordem em que os pontos devem ser visitados.
 *
 * Exemplo:
 *
 *     1 -> Praça Central
 *     2 -> Escola Municipal Primavera
 *     3 -> Terminal Rodoviário
 */

CREATE TABLE IF NOT EXISTS rota_ponto (
    id_rota INT NOT NULL
        REFERENCES rota(id),

    id_ponto_embarque INT NOT NULL
        REFERENCES ponto_embarque(id),

    ordem_parada INT NOT NULL,
    horario_estimado TIME NOT NULL,

    CONSTRAINT rota_ponto_pk
        PRIMARY KEY (id_rota,
id_ponto_embarque)
);

/* ============================================================
 * REGISTRO_PRESENCA
 * ============================================================
 *
 * Representa o registro da presença de um aluno durante uma
 * viagem.
 *
 * Cada registro informa:
 *
 * - quando ocorreu;
 * - status da presença;
 * - qual viagem;
 * - qual aluno;
 * - qual ponto de embarque.
 */

CREATE TABLE IF NOT EXISTS registro_presenca (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    data_hora TIMESTAMP NOT NULL,
    status_presenca VARCHAR(20) NOT NULL,

    id_viagem INT NOT NULL
        REFERENCES viagem(id),

    id_aluno INT NOT NULL
        REFERENCES aluno(id),

    id_ponto_embarque INT NOT NULL
        REFERENCES ponto_embarque(id)
);

/* ============================================================
 * POPULACAO INICIAL DAS TABELAS
 * ============================================================
 *
 * Os INSERTs precisam respeitar a ordem das dependências.
 *
 * Primeiro inserimos dados nas tabelas independentes.
 * Depois inserimos nas tabelas que possuem Foreign Keys.
 */


/* ============================================================
 * RESPONSAVEL
 * ============================================================
 *
 * Não informamos o id porque ele é gerado automaticamente
 * através de GENERATED ALWAYS AS IDENTITY.
 */

INSERT
	INTO
	responsavel (
    cpf,
	telefone,
	email,
	endereco
)
VALUES
    (
        '12345678901',
        '94991234567',
        'carlos.silva@email.com',
        'Rua das Flores, 120'
    ),
    (
        '23456789012',
        '94992345678',
        'ana.souza@email.com',
        'Avenida Brasil, 450'
    ),
    (
        '34567890123',
        '94993456789',
        'marcos.oliveira@email.com',
        'Rua Pará, 88'
    ),
    (
        '45678901234',
        '94994567890',
        'juliana.costa@email.com',
        'Rua Amazonas, 305'
    ),
    (
        '56789012345',
        '94995678901',
        'roberto.almeida@email.com',
        'Avenida Liberdade, 740'
    );

/* ============================================================
 * PONTO_EMBARQUE
 * ============================================================
 */

INSERT
	INTO
	ponto_embarque (
    descricao,
	latitude,
	longitude
)
VALUES
    (
        'Praça Central',
        -6.06741900,
        -49.90222100
    ),
    (
        'Escola Municipal Primavera',
        -6.07235000,
        -49.89561000
    ),
    (
        'Terminal Rodoviário',
        -6.06324000,
        -49.90783000
    ),
    (
        'Praça do Bairro Cidade Nova',
        -6.07548000,
        -49.91326000
    ),
    (
        'Avenida dos Ipês',
        -6.05891000,
        -49.89932000
    );

/* ============================================================
 * MOTORISTA
 * ============================================================
 */

INSERT
	INTO
	motorista (
    nome,
	cpf,
	cnh,
	telefone
)
VALUES
    (
        'João Ferreira',
        '11122233344',
        'CNH001234567',
        '94991112222'
    ),
    (
        'Maria Oliveira',
        '22233344455',
        'CNH002345678',
        '94992223333'
    ),
    (
        'Paulo Mendes',
        '33344455566',
        'CNH003456789',
        '94993334444'
    );

/* ============================================================
 * VEICULO
 * ============================================================
 *
 * Todos os valores de capacidade são maiores que zero,
 * respeitando:
 *
 *     CHECK (capacidade > 0)
 */

INSERT
	INTO
	veiculo (
    placa,
	modelo,
	capacidade
)
VALUES
    (
        'ABC1D23',
        'Mercedes-Benz Sprinter',
        20
    ),
    (
        'DEF4G56',
        'Volkswagen Escolarbus',
        32
    ),
    (
        'GHI7J89',
        'Iveco Daily Minibus',
        18
    );

/* ============================================================
 * ALUNO
 * ============================================================
 *
 * Os valores de id_responsavel e id_ponto_embarque são
 * Foreign Keys.
 *
 * Assumindo que os IDs foram gerados a partir de 1:
 *
 * responsavel:
 *     1 até 5
 *
 * ponto_embarque:
 *     1 até 5
 */

INSERT
	INTO
	aluno (
    nome,
	data_nascimento,
	serie,
	id_responsavel,
	id_ponto_embarque
)
VALUES
    ('Gabriel Silva',
'2014-03-12',
'6º Ano',
1,
1),
    ('Mariana Silva',
'2016-07-21',
'4º Ano',
1,
1),
    ('Lucas Souza',
'2013-10-05',
'7º Ano',
2,
2),
    ('Sofia Souza',
'2015-02-18',
'5º Ano',
2,
3),
    ('Pedro Oliveira',
'2012-11-30',
'8º Ano',
3,
2),
    ('Beatriz Costa',
'2014-05-16',
'6º Ano',
4,
4),
    ('Rafael Almeida',
'2013-08-09',
'7º Ano',
5,
5),
    ('Laura Almeida',
'2016-01-27',
'4º Ano',
5,
5);

/* ============================================================
 * ROTA
 * ============================================================
 *
 * Cada registro referencia:
 *
 *     id_veiculo
 *     id_motorista
 */

INSERT
	INTO
	rota (
    nome_rota,
	turno,
	horario_partida,
	horario_chegada,
	id_veiculo,
	id_motorista
)
VALUES
    (
        'Rota Norte',
        'Manhã',
        '06:00:00',
        '07:20:00',
        1,
        1
    ),
    (
        'Rota Sul',
        'Manhã',
        '06:15:00',
        '07:30:00',
        2,
        2
    ),
    (
        'Rota Centro',
        'Tarde',
        '12:30:00',
        '13:45:00',
        3,
        3
    );

/* ============================================================
 * ROTA_PONTO
 * ============================================================
 *
 * Aqui relacionamos as rotas aos seus respectivos pontos.
 *
 * Estrutura:
 *
 * (id_rota, id_ponto_embarque, ordem_parada, horario_estimado)
 */

INSERT
	INTO
	rota_ponto (
    id_rota,
	id_ponto_embarque,
	ordem_parada,
	horario_estimado
)
VALUES
    /* Rota Norte */
    (1,
1,
1,
'06:10:00'),
    (1,
2,
2,
'06:30:00'),
    (1,
3,
3,
'06:50:00'),

    /* Rota Sul */
    (2,
2,
1,
'06:25:00'),
    (2,
4,
2,
'06:50:00'),

    /* Rota Centro */
    (3,
3,
1,
'12:40:00'),
    (3,
5,
2,
'13:00:00');

/* ============================================================
 * VIAGEM
 * ============================================================
 *
 * Cada linha representa uma execução concreta de uma rota.
 *
 * Exemplo:
 *
 * id_rota = 1
 *
 * significa que aquela viagem é uma execução da Rota Norte.
 */

INSERT
	INTO
	viagem (
    data_viagem,
	horario_inicio,
	horario_fim,
	status,
	id_rota,
	id_motorista,
	id_veiculo
)
VALUES
    (
        '2026-09-17',
        '2026-09-17 06:00:00',
        '2026-09-17 07:18:00',
        'FINALIZADA',
        1,
        1,
        1
    ),
    (
        '2026-09-17',
        '2026-09-17 06:15:00',
        '2026-09-17 07:27:00',
        'FINALIZADA',
        2,
        2,
        2
    ),
    (
        '2026-09-17',
        '2026-09-17 12:30:00',
        '2026-09-17 13:42:00',
        'FINALIZADA',
        3,
        3,
        3
    ),
    (
        '2026-09-18',
        '2026-09-18 06:00:00',
        '2026-09-18 07:21:00',
        'FINALIZADA',
        1,
        1,
        1
    );

/* ============================================================
 * REGISTRO_PRESENCA
 * ============================================================
 *
 * Registra a situação dos alunos em cada viagem.
 *
 * Estrutura:
 *
 * (
 *     data_hora,
 *     status_presenca,
 *     id_viagem,
 *     id_aluno,
 *     id_ponto_embarque
 * )
 */

INSERT
	INTO
	registro_presenca (
    data_hora,
	status_presenca,
	id_viagem,
	id_aluno,
	id_ponto_embarque
)
VALUES
    /* Viagem 1 - Rota Norte */
    ('2026-09-17 06:09:15',
'PRESENTE',
1,
1,
1),
    ('2026-09-17 06:09:42',
'PRESENTE',
1,
2,
1),
    ('2026-09-17 06:29:31',
'PRESENTE',
1,
3,
2),
    ('2026-09-17 06:49:05',
'AUSENTE',
1,
4,
3),

    /* Viagem 2 - Rota Sul */
    ('2026-09-17 06:24:20',
'PRESENTE',
2,
5,
2),
    ('2026-09-17 06:49:37',
'PRESENTE',
2,
6,
4),

    /* Viagem 3 - Rota Centro */
    ('2026-09-17 12:59:10',
'PRESENTE',
3,
7,
5),
    ('2026-09-17 12:59:35',
'PRESENTE',
3,
8,
5),

    /* Viagem 4 - Rota Norte */
    ('2026-09-18 06:09:12',
'PRESENTE',
4,
1,
1),
    ('2026-09-18 06:09:39',
'AUSENTE',
4,
2,
1),
    ('2026-09-18 06:30:03',
'PRESENTE',
4,
3,
2),
    ('2026-09-18 06:50:11',
'PRESENTE',
4,
4,
3);



/* ============================================================
 * ATUALIZACAO DAS TABELAS
 * ============================================================
 *
 * UPDATE modifica registros que já existem.
 *
 * Estrutura geral:
 *
 *     UPDATE tabela
 *     SET coluna = novo_valor
 *     WHERE condição;
 *
 * O WHERE determina quais registros serão modificados.
 */


/*
 * Atualiza somente o responsável cujo id seja igual a 1.
 */

UPDATE
	responsavel
SET
	email = 'carlos.decornos.silva@gmail.com'
WHERE
	id = 1;

/*
 * Atualiza somente o motorista cujo id seja igual a 1.
 *
 * Se o WHERE fosse removido, TODOS os motoristas teriam
 * o nome alterado.
 */

UPDATE
	motorista
SET
	nome = 'Sir. Perv El Tido'
WHERE
	id = 1;UPDATE
	responsavel
SET
	email = 'carlos.decornos.silva@gmail.com'
WHERE
	id = 1;

/*
 * Atualiza somente o motorista cujo id seja igual a 1.
 *
 * Se o WHERE fosse removido, TODOS os motoristas teriam
 * o nome alterado.
 */

UPDATE
	motorista
SET
	nome = 'Sir. Perv El Tido'
WHERE
	id = 1;


/* ============================================================
 * CONSULTAS DAS TABELAS
 * ============================================================
 *
 * SELECT consulta registros armazenados no banco.
 *
 * JOIN permite combinar informações provenientes de tabelas
 * diferentes através dos seus relacionamentos.
 */


/*
 * 1. Quem são os responsáveis dos alunos?
 *
 * LEFT JOIN:
 *
 * Retorna todos os registros da tabela posicionada à esquerda
 * (aluno), mesmo que não exista um responsável correspondente.
 *
 * A condição:
 *
 *     aluno.id_responsavel = responsavel.id
 *
 * define como os registros das duas tabelas devem ser
 * relacionados.
 */


SELECT
	*
FROM
	aluno
LEFT JOIN responsavel
    ON
	aluno.id_responsavel = responsavel.id;

/*
 * 2. Quais são as rotas de cada viagem?
 *
 * viagem.id_rota é a Foreign Key que aponta para rota.id.
 */

SELECT
	*
FROM
	viagem
LEFT JOIN rota
    ON
	viagem.id_rota = rota.id;

/*
 * 3. Quem são os alunos presentes?
 *
 * Primeiro relacionamos aluno e registro_presenca.
 *
 * Depois utilizamos WHERE para manter somente registros cujo
 * status seja PRESENTE.
 *
 * Apesar de utilizarmos LEFT JOIN, a condição no WHERE exige
 * que exista um registro_presenca com status PRESENTE.
 */

SELECT
	*
FROM
	aluno
LEFT JOIN registro_presenca
    ON
	aluno.id = registro_presenca.id_aluno
WHERE
	registro_presenca.status_presenca = 'PRESENTE';




/* ============================================================
 * LIMPEZA DAS TABELAS
 * ============================================================
 * O TRUNCATE TABLE deleta todos os registros de uma tabela
 * RESTART IDENTITY: Irá reiniciar a Sequence responsável pelos IDs.
 * CASCADE: Deletará em cascata todas as referências a algum registro da 
 * tabela que está sendo limpa.
 * 
 * Obs: Ele não deleta a tabela, ele apenas limpa.
 */

TRUNCATE TABLE responsavel  RESTART IDENTITY CASCADE;
TRUNCATE TABLE ponto_embarque RESTART IDENTITY CASCADE;
TRUNCATE TABLE aluno RESTART IDENTITY CASCADE;
TRUNCATE TABLE motorista RESTART IDENTITY CASCADE;
TRUNCATE TABLE veiculo RESTART IDENTITY CASCADE;
TRUNCATE TABLE rota RESTART IDENTITY CASCADE;
TRUNCATE TABLE rota_ponto RESTART IDENTITY CASCADE;
TRUNCATE TABLE viagem RESTART IDENTITY CASCADE;
TRUNCATE TABLE registro_presenca CASCADE;

/* ============================================================
 * DELECAO DAS TABELAS
 * ============================================================
 *
 * DROP TABLE remove a própria estrutura da tabela.
 *
 * Não confundir com:
 *
 *     DELETE FROM tabela;
 *
 * DELETE remove registros.
 *
 * DROP TABLE remove a tabela.
 *
 *
 * CASCADE
 *
 * CASCADE também remove dependências relacionadas ao objeto
 * que está sendo excluído.
 *
 * Por isso, deve ser utilizado com cuidado.
 *
 * ATENÇÃO:
 *
 * Os comandos abaixo DESTROEM as tabelas criadas anteriormente.
 * Eles normalmente devem ser utilizados apenas quando você
 * realmente desejar remover o banco de testes.
 */



DROP TABLE responsavel CASCADE;

DROP TABLE ponto_embarque CASCADE;

DROP TABLE aluno CASCADE ;

DROP TABLE motorista CASCADE;

DROP TABLE veiculo CASCADE;

DROP TABLE rota CASCADE;

DROP TABLE rota_ponto CASCADE;

DROP TABLE viagem CASCADE;

DROP TABLE registro_presenca CASCADE;
