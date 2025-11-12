-- Active: 1762080270873@@127.0.0.1@3306@foodadvisor
INSERT INTO
    role (code)
VALUES ('ADMIN'),
    ('USER')
ON DUPLICATE KEY UPDATE
    code = VALUES(code);

-- admin de base
INSERT INTO
    utilisateur (
        email,
        hash_mdp,
        nom,
        prenom,
        date_naissance,
        ville,
        actif
    )
VALUES (
        'admin@foodadvisor.local',
        '$2b$10$U3yDqtE9nXlDZ4TlDsETX.RbKdPvXDBponNrFO0zHGTYWQnQDLGti', -- mdp = admin123
        'Admin',
        'FoodAdvisor',
        NULL,
        NULL,
        1
    )
ON DUPLICATE KEY UPDATE
    email = email;

-- lier à ADMIN
INSERT INTO
    utilisateur_role (utilisateur_id, role_id)
SELECT u.id, r.id
FROM utilisateur u, role r
WHERE
    u.email = 'admin@foodadvisor.local'
    AND r.code = 'ADMIN'
ON DUPLICATE KEY UPDATE
    utilisateur_id = utilisateur_id;