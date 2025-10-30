-- ==========================================================
--  FOODADVISOR - INSTALLATION COMPLÈTE (VERSION FINALE)
--  Auteur : Sefa TAS & Minel KUJUNDZIC
--  Date : 2025-10-11
--  Description : Installation complète + données massives + procédures + vues + triggers
-- ==========================================================

-- Étape 1 : Création / Réinitialisation
DROP DATABASE IF EXISTS foodadvisor;

CREATE DATABASE foodadvisor CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE foodadvisor;

-- Désactivation temporaire des FK
SET FOREIGN_KEY_CHECKS = 0;

-- Suppression propre de tous les objets (dans l’ordre logique)
DROP VIEW IF EXISTS v_recette_note;

DROP VIEW IF EXISTS v_prix_courant;

DROP VIEW IF EXISTS v_cout_recette;

DROP TRIGGER IF EXISTS trg_stock_ai;

DROP TRIGGER IF EXISTS trg_stock_au;

DROP PROCEDURE IF EXISTS sp_cuire_recette;

DROP TABLE IF EXISTS liste_course_item,
liste_course,
avis,
historique_cuisson,
mvt_stock,
stock,
recette_ingredient,
etape_recette,
recette,
prix_ingredient,
ingredient_allergene,
ingredient,
unite,
allergene,
categorie_ingredient,
utilisateur_regime,
utilisateur_role,
regime,
role,
utilisateur;

SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================
-- Étape 2 : Création du schéma (DDL)
-- ==========================================================

CREATE TABLE role (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE utilisateur (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(190) NOT NULL UNIQUE,
    hash_mdp VARCHAR(255) NOT NULL,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    age TINYINT UNSIGNED,
    ville VARCHAR(120),
    date_inscription DATETIME DEFAULT CURRENT_TIMESTAMP,
    actif TINYINT(1) DEFAULT 1
) ENGINE = InnoDB;

CREATE TABLE utilisateur_role (
    utilisateur_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (utilisateur_id, role_id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE categorie_ingredient (
    id INT AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(120) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE allergene (
    id INT AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(120) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE unite (
    code VARCHAR(16) PRIMARY KEY,
    libelle VARCHAR(50) NOT NULL,
    type ENUM('masse', 'volume', 'piece') NOT NULL
) ENGINE = InnoDB;

CREATE TABLE ingredient (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(190) NOT NULL UNIQUE,
    categorie_id INT NOT NULL,
    kcal_100g DECIMAL(6, 1),
    prot_100g DECIMAL(6, 2),
    gluc_100g DECIMAL(6, 2),
    lip_100g DECIMAL(6, 2),
    prix_ref DECIMAL(8, 2),
    FOREIGN KEY (categorie_id) REFERENCES categorie_ingredient (id)
) ENGINE = InnoDB;

CREATE TABLE ingredient_allergene (
    ingredient_id INT NOT NULL,
    allergene_id INT NOT NULL,
    PRIMARY KEY (ingredient_id, allergene_id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredient (id) ON DELETE CASCADE,
    FOREIGN KEY (allergene_id) REFERENCES allergene (id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE prix_ingredient (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ingredient_id INT NOT NULL,
    date_effet DATE NOT NULL,
    prix_unitaire DECIMAL(8, 2) NOT NULL,
    UNIQUE KEY uniq_prix (ingredient_id, date_effet),
    FOREIGN KEY (ingredient_id) REFERENCES ingredient (id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE recette (
    id INT AUTO_INCREMENT PRIMARY KEY,
    auteur_id INT NOT NULL,
    titre VARCHAR(190) NOT NULL,
    description TEXT,
    personnes_defaut TINYINT UNSIGNED DEFAULT 2,
    cout_cache DECIMAL(10, 2),
    note_cache DECIMAL(3, 2),
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    publie TINYINT(1) DEFAULT 1,
    FOREIGN KEY (auteur_id) REFERENCES utilisateur (id)
) ENGINE = InnoDB;

CREATE TABLE etape_recette (
    recette_id INT NOT NULL,
    ord SMALLINT UNSIGNED NOT NULL,
    description TEXT NOT NULL,
    PRIMARY KEY (recette_id, ord),
    FOREIGN KEY (recette_id) REFERENCES recette (id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE recette_ingredient (
    recette_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantite DECIMAL(10, 3) NOT NULL,
    unite_code VARCHAR(16) NOT NULL,
    PRIMARY KEY (recette_id, ingredient_id),
    FOREIGN KEY (recette_id) REFERENCES recette (id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredient (id),
    FOREIGN KEY (unite_code) REFERENCES unite (code)
) ENGINE = InnoDB;

CREATE TABLE stock (
    utilisateur_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantite DECIMAL(10, 3) DEFAULT 0,
    unite_code VARCHAR(16) NOT NULL,
    date_peremption DATE NULL,
    PRIMARY KEY (utilisateur_id, ingredient_id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredient (id),
    FOREIGN KEY (unite_code) REFERENCES unite (code)
) ENGINE = InnoDB;

CREATE TABLE mvt_stock (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    delta DECIMAL(10, 3) NOT NULL,
    unite_code VARCHAR(16) NOT NULL,
    raison ENUM(
        'ajout',
        'retrait',
        'correction',
        'cuisson',
        'peremption'
    ) NOT NULL,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredient (id),
    FOREIGN KEY (unite_code) REFERENCES unite (code)
) ENGINE = InnoDB;

CREATE TABLE regime (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE,
    libelle VARCHAR(120) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE utilisateur_regime (
    utilisateur_id INT NOT NULL,
    regime_id INT NOT NULL,
    PRIMARY KEY (utilisateur_id, regime_id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id) ON DELETE CASCADE,
    FOREIGN KEY (regime_id) REFERENCES regime (id)
) ENGINE = InnoDB;

CREATE TABLE historique_cuisson (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    recette_id INT NOT NULL,
    personnes TINYINT UNSIGNED DEFAULT 1,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id),
    FOREIGN KEY (recette_id) REFERENCES recette (id)
) ENGINE = InnoDB;

CREATE TABLE avis (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    recette_id INT NOT NULL,
    note TINYINT UNSIGNED CHECK (note BETWEEN 1 AND 5),
    commentaire TEXT,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_avis (utilisateur_id, recette_id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id),
    FOREIGN KEY (recette_id) REFERENCES recette (id)
) ENGINE = InnoDB;

CREATE TABLE liste_course (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT NOT NULL,
    libelle VARCHAR(190) NOT NULL,
    ts DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateur (id)
) ENGINE = InnoDB;

CREATE TABLE liste_course_item (
    liste_id BIGINT NOT NULL,
    ingredient_id INT NOT NULL,
    quantite DECIMAL(10, 3) NOT NULL,
    unite_code VARCHAR(16) NOT NULL,
    PRIMARY KEY (liste_id, ingredient_id),
    FOREIGN KEY (liste_id) REFERENCES liste_course (id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredient (id),
    FOREIGN KEY (unite_code) REFERENCES unite (code)
) ENGINE = InnoDB;

-- ==========================================================
-- Étape 3 : Données factices massives
-- ==========================================================

-- Roles
INSERT INTO
    role (code)
VALUES ('ADMIN'),
    ('USER')
ON DUPLICATE KEY UPDATE
    code = VALUES(code);

-- Categories
INSERT INTO
    categorie_ingredient (libelle)
VALUES ('Légume'),
    ('Fruit'),
    ('Viande'),
    ('Poisson'),
    ('Féculent'),
    ('Produit laitier'),
    ('Épice'),
    ('Céréale'),
    ('Boisson'),
    ('Sauce'),
    ('Herbe'),
    ('Oeuf'),
    ('Sucre'),
    ('Condiment'),
    ('Autre')
ON DUPLICATE KEY UPDATE
    libelle = VALUES(libelle);

-- Allergenes
INSERT INTO
    allergene (libelle)
VALUES ('Gluten'),
    ('Lactose'),
    ('Oeuf'),
    ('Arachide'),
    ('Soja'),
    ('Fruits à coque'),
    ('Crustacés'),
    ('Poisson'),
    ('Sésame')
ON DUPLICATE KEY UPDATE
    libelle = VALUES(libelle);

-- Unites
INSERT INTO
    unite (code, libelle, type)
VALUES ('g', 'gramme', 'masse'),
    ('kg', 'kilogramme', 'masse'),
    ('ml', 'millilitre', 'volume'),
    ('l', 'litre', 'volume'),
    ('pce', 'pièce', 'piece')
ON DUPLICATE KEY UPDATE
    libelle = VALUES(libelle),
    type = VALUES(type);

-- Regimes
INSERT INTO
    regime (code, libelle)
VALUES ('VGT', 'Végétarien'),
    ('VGN', 'Végétalien'),
    ('HALAL', 'Halal'),
    ('KOSHER', 'Kasher'),
    ('GLUTEN_FREE', 'Sans gluten'),
    ('DAIRY_FREE', 'Sans lactose'),
    ('HIGH_PROT', 'Hyperprotéiné'),
    ('LOW_FAT', 'Hypolipidique'),
    ('LOW_CARB', 'Cétogène'),
    ('CLASSIC', 'Standard')
ON DUPLICATE KEY UPDATE
    libelle = VALUES(libelle);

-- Ingredients (~120)
INSERT INTO
    ingredient (
        nom,
        categorie_id,
        kcal_100g,
        prot_100g,
        gluc_100g,
        lip_100g,
        prix_ref
    )
VALUES (
        'Tomate',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        79,
        0.58,
        9.6,
        0.0,
        1.55
    ),
    (
        'Pomme de terre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Féculent'
        ),
        378,
        9.22,
        49.2,
        5.7,
        3.1
    ),
    (
        'Carotte',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        63,
        1.01,
        12.6,
        0.8,
        1.02
    ),
    (
        'Oignon',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        30,
        2.53,
        8.1,
        0.2,
        3.39
    ),
    (
        'Poulet',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Viande'
        ),
        206,
        19.23,
        0.8,
        9.0,
        9.1
    ),
    (
        'Boeuf',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Viande'
        ),
        187,
        27.69,
        1.5,
        11.5,
        14.76
    ),
    (
        'Saumon',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Poisson'
        ),
        216,
        18.95,
        0.6,
        12.8,
        13.97
    ),
    (
        'Riz',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        305,
        8.93,
        58.0,
        0.4,
        1.68
    ),
    (
        'Pâtes',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        268,
        13.82,
        67.2,
        6.9,
        2.14
    ),
    (
        'Beurre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        272,
        17.26,
        2.8,
        11.8,
        2.05
    ),
    (
        'Lait',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        176,
        18.84,
        4.4,
        2.3,
        4.17
    ),
    (
        'Crème',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        313,
        19.5,
        1.8,
        12.1,
        5.95
    ),
    (
        'Sel',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Épice'
        ),
        295,
        3.03,
        13.6,
        9.2,
        0.67
    ),
    (
        'Poivre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Épice'
        ),
        26,
        9.76,
        16.6,
        0.8,
        3.24
    ),
    (
        'Persil',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Herbe'
        ),
        300,
        10.58,
        13.3,
        7.9,
        1.69
    ),
    (
        'Citron',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        68,
        0.76,
        4.5,
        0.7,
        2.35
    ),
    (
        'Farine',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        339,
        12.77,
        39.4,
        1.8,
        3.99
    ),
    (
        'Oeuf',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Oeuf'
        ),
        521,
        9.87,
        60.5,
        77.5,
        1.34
    ),
    (
        'Sucre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Sucre'
        ),
        163,
        15.84,
        33.8,
        5.7,
        2.6
    ),
    (
        'Huile d''olive',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Condiment'
        ),
        479,
        10.58,
        77.7,
        77.5,
        0.56
    ),
    (
        'Pain',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        178,
        10.18,
        47.8,
        2.1,
        2.92
    ),
    (
        'Saumon fumé',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Poisson'
        ),
        148,
        21.52,
        0.3,
        4.0,
        12.5
    ),
    (
        'Pomme',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        43,
        3.41,
        15.7,
        0.5,
        1.27
    ),
    (
        'Banane',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        90,
        1.26,
        13.5,
        0.6,
        1.38
    ),
    (
        'Fromage râpé',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        122,
        14.95,
        4.9,
        17.0,
        1.0
    ),
    (
        'Yaourt nature',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        205,
        13.73,
        1.6,
        11.6,
        5.93
    ),
    (
        'Thon',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Poisson'
        ),
        198,
        20.87,
        0.5,
        11.9,
        6.71
    ),
    (
        'Ail',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        72,
        2.91,
        19.6,
        0.5,
        1.31
    ),
    (
        'Courgette',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        70,
        3.33,
        5.0,
        0.5,
        2.52
    ),
    (
        'Champignon',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        37,
        3.27,
        15.6,
        0.7,
        2.78
    ),
    (
        'Epinards',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        61,
        3.48,
        13.7,
        0.4,
        2.29
    ),
    (
        'Lentilles',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        181,
        4.97,
        18.9,
        0.2,
        2.66
    ),
    (
        'Pois chiches',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        232,
        2.09,
        58.2,
        0.5,
        1.2
    ),
    (
        'Quinoa',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        136,
        12.32,
        19.3,
        1.9,
        3.01
    ),
    (
        'Couscous',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        229,
        8.47,
        59.1,
        7.1,
        2.73
    ),
    (
        'Maïs',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        41,
        2.81,
        16.5,
        0.2,
        1.24
    ),
    (
        'Concombre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        65,
        1.43,
        9.4,
        0.9,
        1.14
    ),
    (
        'Poivron rouge',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        22,
        0.49,
        15.1,
        0.8,
        1.27
    ),
    (
        'Poivron vert',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        34,
        0.91,
        10.1,
        0.4,
        1.7
    ),
    (
        'Dinde',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Viande'
        ),
        183,
        28.49,
        0.2,
        15.3,
        13.7
    ),
    (
        'Agneau',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Viande'
        ),
        145,
        18.61,
        2.0,
        15.7,
        14.72
    ),
    (
        'Crevettes',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Poisson'
        ),
        180,
        20.0,
        1.0,
        7.0,
        9.61
    ),
    (
        'Cabillaud',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Poisson'
        ),
        135,
        19.98,
        0.0,
        9.5,
        14.34
    ),
    (
        'Thym',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Herbe'
        ),
        242,
        3.78,
        28.2,
        8.8,
        2.85
    ),
    (
        'Basilic',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Herbe'
        ),
        259,
        2.28,
        12.6,
        11.6,
        2.24
    ),
    (
        'Coriandre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Herbe'
        ),
        287,
        1.2,
        13.2,
        0.6,
        1.93
    ),
    (
        'Curry',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Épice'
        ),
        281,
        2.31,
        38.5,
        1.0,
        1.06
    ),
    (
        'Paprika',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Épice'
        ),
        44,
        8.26,
        10.2,
        1.4,
        3.17
    ),
    (
        'Cumin',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Épice'
        ),
        136,
        7.16,
        2.5,
        1.0,
        2.47
    ),
    (
        'Gingembre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Épice'
        ),
        299,
        6.51,
        37.5,
        2.5,
        2.65
    ),
    (
        'Miel',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Sucre'
        ),
        244,
        5.31,
        10.5,
        58.1,
        3.01
    ),
    (
        'Vinaigre balsamique',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Sauce'
        ),
        769,
        18.71,
        0.7,
        55.9,
        3.6
    ),
    (
        'Sauce soja',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Sauce'
        ),
        102,
        1.47,
        17.1,
        23.9,
        5.63
    ),
    (
        'Mayonnaise',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Sauce'
        ),
        70,
        17.59,
        29.6,
        14.2,
        5.09
    ),
    (
        'Moutarde',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Condiment'
        ),
        720,
        6.05,
        78.7,
        72.6,
        3.41
    ),
    (
        'Ketchup',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Sauce'
        ),
        683,
        16.34,
        24.0,
        59.7,
        5.66
    ),
    (
        'Chapelure',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        188,
        5.17,
        69.3,
        5.9,
        1.47
    ),
    (
        'Noix',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        288,
        12.1,
        57.4,
        18.3,
        3.99
    ),
    (
        'Amandes',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        270,
        10.11,
        20.1,
        81.7,
        0.78
    ),
    (
        'Noisettes',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        649,
        8.47,
        22.1,
        0.3,
        4.74
    ),
    (
        'Beurre de cacahuète',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        652,
        19.6,
        12.9,
        39.8,
        4.38
    ),
    (
        'Lait de coco',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        327,
        2.23,
        1.4,
        28.3,
        5.52
    ),
    (
        'Fromage blanc',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        319,
        2.86,
        2.8,
        17.7,
        3.15
    ),
    (
        'Parmesan',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        61,
        9.4,
        5.5,
        25.5,
        5.3
    ),
    (
        'Mozzarella',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        223,
        7.04,
        2.2,
        3.3,
        4.9
    ),
    (
        'Feta',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        248,
        25.37,
        4.7,
        29.6,
        2.18
    ),
    (
        'Olives',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        166,
        19.52,
        64.9,
        79.3,
        0.64
    ),
    (
        'Courge',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        52,
        2.8,
        9.4,
        0.7,
        2.84
    ),
    (
        'Patate douce',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Féculent'
        ),
        247,
        5.2,
        63.0,
        0.9,
        3.62
    ),
    (
        'Brocoli',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        70,
        1.01,
        16.7,
        0.5,
        1.76
    ),
    (
        'Chou-fleur',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        39,
        1.01,
        13.9,
        0.4,
        1.7
    ),
    (
        'Chou',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        18,
        3.39,
        7.0,
        0.6,
        2.0
    ),
    (
        'Roquette',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        78,
        1.36,
        2.5,
        0.9,
        1.65
    ),
    (
        'Salade',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        84,
        3.38,
        6.8,
        0.1,
        2.09
    ),
    (
        'Betterave',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        50,
        1.7,
        19.7,
        0.1,
        3.25
    ),
    (
        'Aubergine',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        34,
        1.12,
        14.8,
        0.0,
        3.31
    ),
    (
        'Sardines',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Poisson'
        ),
        257,
        26.24,
        1.9,
        14.3,
        7.77
    ),
    (
        'Morue',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Poisson'
        ),
        230,
        18.84,
        1.3,
        8.6,
        8.83
    ),
    (
        'Haricots rouges',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        183,
        10.64,
        33.3,
        2.5,
        2.23
    ),
    (
        'Haricots blancs',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        326,
        10.37,
        48.8,
        1.5,
        2.99
    ),
    (
        'Flocons d''avoine',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        314,
        10.13,
        70.1,
        4.9,
        1.9
    ),
    (
        'Orge',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        120,
        5.65,
        27.8,
        6.3,
        2.82
    ),
    (
        'Seigle',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        284,
        7.58,
        42.0,
        1.7,
        2.42
    ),
    (
        'Épeautre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        206,
        9.91,
        32.3,
        5.3,
        2.86
    ),
    (
        'Bouillon de légumes',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        95,
        16.37,
        60.1,
        60.6,
        1.74
    ),
    (
        'Bouillon de volaille',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        203,
        2.95,
        3.7,
        88.6,
        3.86
    ),
    (
        'Eau',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Boisson'
        ),
        786,
        1.46,
        33.2,
        56.7,
        1.57
    ),
    (
        'Jus d''orange',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Boisson'
        ),
        713,
        7.68,
        32.0,
        13.3,
        4.28
    ),
    (
        'Thé',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Boisson'
        ),
        768,
        17.21,
        70.8,
        70.1,
        1.7
    ),
    (
        'Café',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Boisson'
        ),
        823,
        19.16,
        41.4,
        4.5,
        1.87
    ),
    (
        'Poire',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        25,
        1.76,
        16.4,
        0.7,
        3.47
    ),
    (
        'Fraises',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        86,
        1.32,
        15.6,
        0.4,
        3.04
    ),
    (
        'Framboises',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        74,
        1.67,
        18.3,
        0.4,
        1.4
    ),
    (
        'Myrtilles',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        70,
        1.74,
        15.5,
        0.8,
        1.69
    ),
    (
        'Ananas',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        76,
        1.85,
        6.3,
        0.4,
        2.78
    ),
    (
        'Mangue',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        40,
        1.17,
        7.8,
        0.5,
        1.35
    ),
    (
        'Kiwi',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Fruit'
        ),
        39,
        1.53,
        4.8,
        0.2,
        2.04
    ),
    (
        'Piment',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Épice'
        ),
        179,
        6.74,
        17.2,
        2.5,
        1.76
    ),
    (
        'Curcuma',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Épice'
        ),
        20,
        10.35,
        30.9,
        4.6,
        0.52
    ),
    (
        'Romarin',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Herbe'
        ),
        190,
        3.93,
        16.2,
        10.7,
        3.01
    ),
    (
        'Origan',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Herbe'
        ),
        285,
        9.1,
        22.3,
        7.2,
        1.16
    ),
    (
        'Lardons',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Viande'
        ),
        176,
        21.28,
        1.0,
        9.4,
        12.02
    ),
    (
        'Jambon',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Viande'
        ),
        223,
        26.69,
        1.7,
        16.9,
        14.83
    ),
    (
        'Bacon',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Viande'
        ),
        256,
        18.32,
        0.8,
        11.9,
        6.24
    ),
    (
        'Steak haché',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Viande'
        ),
        229,
        19.63,
        0.9,
        4.7,
        9.41
    ),
    (
        'Tofu',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        216,
        9.09,
        27.0,
        79.2,
        2.03
    ),
    (
        'Tempeh',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        851,
        8.43,
        66.8,
        42.3,
        4.62
    ),
    (
        'Seitan',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        53,
        20.0,
        28.0,
        58.5,
        4.8
    ),
    (
        'Graines de sésame',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        667,
        0.81,
        2.5,
        22.3,
        5.12
    ),
    (
        'Tahini',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Sauce'
        ),
        636,
        3.05,
        10.1,
        60.3,
        3.6
    ),
    (
        'Noix de cajou',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        223,
        9.3,
        20.5,
        33.2,
        3.83
    ),
    (
        'Farine de blé',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        178,
        11.33,
        25.0,
        2.5,
        2.74
    ),
    (
        'Farine de maïs',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        279,
        8.91,
        70.4,
        3.0,
        3.82
    ),
    (
        'Farine de riz',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Céréale'
        ),
        221,
        2.91,
        57.1,
        5.0,
        1.31
    ),
    (
        'Beurre clarifié',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        194,
        22.41,
        4.0,
        3.9,
        5.92
    ),
    (
        'Crème soja',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Autre'
        ),
        801,
        0.82,
        42.6,
        59.5,
        0.88
    ),
    (
        'Fromage de chèvre',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Produit laitier'
        ),
        371,
        10.19,
        5.2,
        26.3,
        1.53
    ),
    (
        'Persil bio 760',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Herbe'
        ),
        195,
        7.81,
        33.3,
        8.5,
        1.81
    ),
    (
        'Maïs séché 229',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Légume'
        ),
        76,
        3.39,
        6.9,
        0.8,
        2.35
    ),
    (
        'Oeuf en conserve 105',
        (
            SELECT id
            FROM categorie_ingredient
            WHERE
                libelle = 'Oeuf'
        ),
        495,
        9.3,
        66.1,
        53.3,
        2.27
    );

-- Ingredient Allergens (subset)
INSERT IGNORE INTO
    ingredient_allergene (ingredient_id, allergene_id)
VALUES (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Poisson'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Gluten'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Oeuf'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pain'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Gluten'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon fumé'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Poisson'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage râpé'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Yaourt nature'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thon'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Poisson'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crevettes'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Crustacés'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crevettes'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Poisson'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Poisson'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sauce soja'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Soja'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre de cacahuète'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre de cacahuète'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Arachide'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait de coco'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage blanc'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sardines'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Poisson'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Morue'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Poisson'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Seigle'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Gluten'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Épeautre'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Gluten'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Sésame'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Gluten'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de maïs'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Gluten'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Gluten'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre clarifié'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème soja'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème soja'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Soja'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage de chèvre'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Lactose'
        )
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf en conserve 105'
        ),
        (
            SELECT id
            FROM allergene
            WHERE
                libelle = 'Oeuf'
        )
    );

-- Users (30 total, 2 admins)
INSERT INTO
    utilisateur (
        email,
        hash_mdp,
        nom,
        prenom,
        age,
        ville
    )
VALUES (
        'admin1@foodadvisor.com',
        'hash1',
        'Admin',
        'Alpha',
        32,
        'Paris'
    ),
    (
        'admin2@foodadvisor.com',
        'hash2',
        'Admin',
        'Beta',
        29,
        'Lyon'
    ),
    (
        'noah.nguyen250@mail.com',
        'hashu',
        'Nguyen',
        'Noah',
        35,
        'Colmar'
    ),
    (
        'jade.petitjean685@mail.com',
        'hashu',
        'Petitjean',
        'Jade',
        54,
        'Paris'
    ),
    (
        'adam.bernard872@mail.com',
        'hashu',
        'Bernard',
        'Adam',
        19,
        'Colmar'
    ),
    (
        'mohamed.moreau364@mail.com',
        'hashu',
        'Moreau',
        'Mohamed',
        49,
        'Besançon'
    ),
    (
        'sami.rousseau902@mail.com',
        'hashu',
        'Rousseau',
        'Sami',
        39,
        'Dijon'
    ),
    (
        'nina.rousseau530@mail.com',
        'hashu',
        'Rousseau',
        'Nina',
        53,
        'Strasbourg'
    ),
    (
        'eva.nguyen501@mail.com',
        'hashu',
        'Nguyen',
        'Eva',
        33,
        'Reims'
    ),
    (
        'chloé.garcia459@mail.com',
        'hashu',
        'Garcia',
        'Chloé',
        48,
        'Colmar'
    ),
    (
        'sami.dupont227@mail.com',
        'hashu',
        'Dupont',
        'Sami',
        23,
        'Dijon'
    ),
    (
        'adam.garcia378@mail.com',
        'hashu',
        'Garcia',
        'Adam',
        37,
        'Paris'
    ),
    (
        'hugo.poirier436@mail.com',
        'hashu',
        'Poirier',
        'Hugo',
        51,
        'Nancy'
    ),
    (
        'inès.poirier720@mail.com',
        'hashu',
        'Poirier',
        'Inès',
        39,
        'Nancy'
    ),
    (
        'amina.rousseau237@mail.com',
        'hashu',
        'Rousseau',
        'Amina',
        37,
        'Dijon'
    ),
    (
        'paul.lemoine761@mail.com',
        'hashu',
        'Lemoine',
        'Paul',
        38,
        'Belfort'
    ),
    (
        'chloé.moreau757@mail.com',
        'hashu',
        'Moreau',
        'Chloé',
        30,
        'Besançon'
    ),
    (
        'hugo.rousseau612@mail.com',
        'hashu',
        'Rousseau',
        'Hugo',
        55,
        'Metz'
    ),
    (
        'liam.durand233@mail.com',
        'hashu',
        'Durand',
        'Liam',
        30,
        'Dijon'
    ),
    (
        'sofia.moreau726@mail.com',
        'hashu',
        'Moreau',
        'Sofia',
        37,
        'Strasbourg'
    ),
    (
        'chloé.petit998@mail.com',
        'hashu',
        'Petit',
        'Chloé',
        35,
        'Strasbourg'
    ),
    (
        'lucas.poirier654@mail.com',
        'hashu',
        'Poirier',
        'Lucas',
        36,
        'Mulhouse'
    ),
    (
        'youssef.marchand588@mail.com',
        'hashu',
        'Marchand',
        'Youssef',
        24,
        'Strasbourg'
    ),
    (
        'liam.marchand349@mail.com',
        'hashu',
        'Marchand',
        'Liam',
        48,
        'Colmar'
    ),
    (
        'yanis.martin117@mail.com',
        'hashu',
        'Martin',
        'Yanis',
        34,
        'Colmar'
    ),
    (
        'léna.nguyen76@mail.com',
        'hashu',
        'Nguyen',
        'Léna',
        43,
        'Colmar'
    ),
    (
        'tom.martin831@mail.com',
        'hashu',
        'Martin',
        'Tom',
        27,
        'Mulhouse'
    ),
    (
        'tom.bonnet122@mail.com',
        'hashu',
        'Bonnet',
        'Tom',
        23,
        'Besançon'
    ),
    (
        'chloé.richard390@mail.com',
        'hashu',
        'Richard',
        'Chloé',
        32,
        'Metz'
    ),
    (
        'amina.petitjean440@mail.com',
        'hashu',
        'Petitjean',
        'Amina',
        37,
        'Paris'
    );

-- User Roles
INSERT IGNORE INTO
    utilisateur_role (utilisateur_id, role_id)
VALUES (
        1,
        (
            SELECT id
            FROM role
            WHERE
                code = 'ADMIN'
        )
    ),
    (
        1,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        2,
        (
            SELECT id
            FROM role
            WHERE
                code = 'ADMIN'
        )
    ),
    (
        2,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        3,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        4,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        5,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        6,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        7,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        8,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        9,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        10,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        11,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        12,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        13,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        14,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        15,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        16,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        17,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        18,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        19,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        20,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        21,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        22,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        23,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        24,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        25,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        26,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        27,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        28,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        29,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    ),
    (
        30,
        (
            SELECT id
            FROM role
            WHERE
                code = 'USER'
        )
    );

-- User regimes (random)
INSERT IGNORE INTO
    utilisateur_regime (utilisateur_id, regime_id)
VALUES (
        3,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'CLASSIC'
        )
    ),
    (
        6,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'KOSHER'
        )
    ),
    (
        7,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'VGN'
        )
    ),
    (
        8,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'KOSHER'
        )
    ),
    (
        9,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'LOW_CARB'
        )
    ),
    (
        11,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'VGT'
        )
    ),
    (
        12,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'LOW_FAT'
        )
    ),
    (
        12,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'CLASSIC'
        )
    ),
    (
        13,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'VGT'
        )
    ),
    (
        14,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'GLUTEN_FREE'
        )
    ),
    (
        15,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'LOW_FAT'
        )
    ),
    (
        17,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'GLUTEN_FREE'
        )
    ),
    (
        18,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'HIGH_PROT'
        )
    ),
    (
        20,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'HALAL'
        )
    ),
    (
        21,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'HALAL'
        )
    ),
    (
        24,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'GLUTEN_FREE'
        )
    ),
    (
        25,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'LOW_FAT'
        )
    ),
    (
        27,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'GLUTEN_FREE'
        )
    ),
    (
        27,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'HIGH_PROT'
        )
    ),
    (
        28,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'LOW_CARB'
        )
    ),
    (
        29,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'LOW_FAT'
        )
    ),
    (
        29,
        (
            SELECT id
            FROM regime
            WHERE
                code = 'VGN'
        )
    );

-- Recipes (30)
INSERT INTO
    recette (
        auteur_id,
        titre,
        description,
        personnes_defaut
    )
VALUES (
        16,
        'Ratatouille maison',
        'Ratatouille maison - recette générée',
        4
    ),
    (
        22,
        'Poulet au curry',
        'Poulet au curry - recette générée',
        4
    ),
    (
        3,
        'Spaghetti bolognaise',
        'Spaghetti bolognaise - recette générée',
        2
    ),
    (
        10,
        'Salade de thon',
        'Salade de thon - recette générée',
        6
    ),
    (
        21,
        'Crêpes sucrées',
        'Crêpes sucrées - recette générée',
        2
    ),
    (
        27,
        'Soupe de légumes',
        'Soupe de légumes - recette générée',
        4
    ),
    (
        21,
        'Riz sauté aux légumes',
        'Riz sauté aux légumes - recette générée',
        2
    ),
    (
        27,
        'Omelette aux champignons',
        'Omelette aux champignons - recette générée',
        3
    ),
    (
        18,
        'Tarte aux pommes',
        'Tarte aux pommes - recette générée',
        6
    ),
    (
        23,
        'Saumon grillé au citron',
        'Saumon grillé au citron - recette générée',
        4
    ),
    (
        11,
        'Couscous végétarien',
        'Couscous végétarien - recette générée',
        3
    ),
    (
        21,
        'Quinoa bowl protéiné',
        'Quinoa bowl protéiné - recette générée',
        4
    ),
    (
        23,
        'Burger maison',
        'Burger maison - recette générée',
        4
    ),
    (
        5,
        'Pizza margherita',
        'Pizza margherita - recette générée',
        4
    ),
    (
        14,
        'Poulet rôti aux herbes',
        'Poulet rôti aux herbes - recette générée',
        4
    ),
    (
        13,
        'Poisson pané croustillant',
        'Poisson pané croustillant - recette générée',
        4
    ),
    (
        24,
        'Boeuf bourguignon',
        'Boeuf bourguignon - recette générée',
        2
    ),
    (
        30,
        'Dahl de lentilles',
        'Dahl de lentilles - recette générée',
        3
    ),
    (
        13,
        'Poke bowl saumon',
        'Poke bowl saumon - recette générée',
        4
    ),
    (
        25,
        'Salade César',
        'Salade César - recette générée',
        4
    ),
    (
        12,
        'Gratin de courgettes',
        'Gratin de courgettes - recette générée',
        4
    ),
    (
        29,
        'Chili sin carne',
        'Chili sin carne - recette générée',
        6
    ),
    (
        4,
        'Paella rapide',
        'Paella rapide - recette générée',
        4
    ),
    (
        5,
        'Wok de dinde',
        'Wok de dinde - recette générée',
        4
    ),
    (
        11,
        'Taboulé frais',
        'Taboulé frais - recette générée',
        4
    ),
    (
        6,
        'Tajine de légumes',
        'Tajine de légumes - recette générée',
        4
    ),
    (
        30,
        'Soupe miso',
        'Soupe miso - recette générée',
        6
    ),
    (
        29,
        'Shakshuka',
        'Shakshuka - recette générée',
        2
    ),
    (
        24,
        'Falafels maison',
        'Falafels maison - recette générée',
        6
    ),
    (
        17,
        'Porridge avoine fruits',
        'Porridge avoine fruits - recette générée',
        4
    );

-- Steps per recipe
INSERT INTO
    etape_recette (recette_id, ord, description)
VALUES (
        1,
        1,
        'Étape 1 pour recette 1'
    ),
    (
        2,
        1,
        'Étape 1 pour recette 2'
    ),
    (
        2,
        2,
        'Étape 2 pour recette 2'
    ),
    (
        3,
        1,
        'Étape 1 pour recette 3'
    ),
    (
        3,
        2,
        'Étape 2 pour recette 3'
    ),
    (
        3,
        3,
        'Étape 3 pour recette 3'
    ),
    (
        4,
        1,
        'Étape 1 pour recette 4'
    ),
    (
        4,
        2,
        'Étape 2 pour recette 4'
    ),
    (
        4,
        3,
        'Étape 3 pour recette 4'
    ),
    (
        4,
        4,
        'Étape 4 pour recette 4'
    ),
    (
        5,
        1,
        'Étape 1 pour recette 5'
    ),
    (
        5,
        2,
        'Étape 2 pour recette 5'
    ),
    (
        5,
        3,
        'Étape 3 pour recette 5'
    ),
    (
        5,
        4,
        'Étape 4 pour recette 5'
    ),
    (
        6,
        1,
        'Étape 1 pour recette 6'
    ),
    (
        7,
        1,
        'Étape 1 pour recette 7'
    ),
    (
        7,
        2,
        'Étape 2 pour recette 7'
    ),
    (
        8,
        1,
        'Étape 1 pour recette 8'
    ),
    (
        8,
        2,
        'Étape 2 pour recette 8'
    ),
    (
        8,
        3,
        'Étape 3 pour recette 8'
    ),
    (
        9,
        1,
        'Étape 1 pour recette 9'
    ),
    (
        9,
        2,
        'Étape 2 pour recette 9'
    ),
    (
        10,
        1,
        'Étape 1 pour recette 10'
    ),
    (
        10,
        2,
        'Étape 2 pour recette 10'
    ),
    (
        10,
        3,
        'Étape 3 pour recette 10'
    ),
    (
        11,
        1,
        'Étape 1 pour recette 11'
    ),
    (
        11,
        2,
        'Étape 2 pour recette 11'
    ),
    (
        11,
        3,
        'Étape 3 pour recette 11'
    ),
    (
        11,
        4,
        'Étape 4 pour recette 11'
    ),
    (
        12,
        1,
        'Étape 1 pour recette 12'
    ),
    (
        12,
        2,
        'Étape 2 pour recette 12'
    ),
    (
        12,
        3,
        'Étape 3 pour recette 12'
    ),
    (
        12,
        4,
        'Étape 4 pour recette 12'
    ),
    (
        13,
        1,
        'Étape 1 pour recette 13'
    ),
    (
        14,
        1,
        'Étape 1 pour recette 14'
    ),
    (
        15,
        1,
        'Étape 1 pour recette 15'
    ),
    (
        15,
        2,
        'Étape 2 pour recette 15'
    ),
    (
        16,
        1,
        'Étape 1 pour recette 16'
    ),
    (
        16,
        2,
        'Étape 2 pour recette 16'
    ),
    (
        17,
        1,
        'Étape 1 pour recette 17'
    ),
    (
        17,
        2,
        'Étape 2 pour recette 17'
    ),
    (
        17,
        3,
        'Étape 3 pour recette 17'
    ),
    (
        18,
        1,
        'Étape 1 pour recette 18'
    ),
    (
        19,
        1,
        'Étape 1 pour recette 19'
    ),
    (
        19,
        2,
        'Étape 2 pour recette 19'
    ),
    (
        19,
        3,
        'Étape 3 pour recette 19'
    ),
    (
        19,
        4,
        'Étape 4 pour recette 19'
    ),
    (
        20,
        1,
        'Étape 1 pour recette 20'
    ),
    (
        21,
        1,
        'Étape 1 pour recette 21'
    ),
    (
        21,
        2,
        'Étape 2 pour recette 21'
    ),
    (
        22,
        1,
        'Étape 1 pour recette 22'
    ),
    (
        23,
        1,
        'Étape 1 pour recette 23'
    ),
    (
        23,
        2,
        'Étape 2 pour recette 23'
    ),
    (
        23,
        3,
        'Étape 3 pour recette 23'
    ),
    (
        23,
        4,
        'Étape 4 pour recette 23'
    ),
    (
        24,
        1,
        'Étape 1 pour recette 24'
    ),
    (
        25,
        1,
        'Étape 1 pour recette 25'
    ),
    (
        25,
        2,
        'Étape 2 pour recette 25'
    ),
    (
        26,
        1,
        'Étape 1 pour recette 26'
    ),
    (
        26,
        2,
        'Étape 2 pour recette 26'
    ),
    (
        26,
        3,
        'Étape 3 pour recette 26'
    ),
    (
        26,
        4,
        'Étape 4 pour recette 26'
    ),
    (
        27,
        1,
        'Étape 1 pour recette 27'
    ),
    (
        27,
        2,
        'Étape 2 pour recette 27'
    ),
    (
        27,
        3,
        'Étape 3 pour recette 27'
    ),
    (
        28,
        1,
        'Étape 1 pour recette 28'
    ),
    (
        28,
        2,
        'Étape 2 pour recette 28'
    ),
    (
        28,
        3,
        'Étape 3 pour recette 28'
    ),
    (
        29,
        1,
        'Étape 1 pour recette 29'
    ),
    (
        29,
        2,
        'Étape 2 pour recette 29'
    ),
    (
        29,
        3,
        'Étape 3 pour recette 29'
    ),
    (
        29,
        4,
        'Étape 4 pour recette 29'
    ),
    (
        30,
        1,
        'Étape 1 pour recette 30'
    ),
    (
        30,
        2,
        'Étape 2 pour recette 30'
    ),
    (
        30,
        3,
        'Étape 3 pour recette 30'
    ),
    (
        30,
        4,
        'Étape 4 pour recette 30'
    );

-- Recipe ingredients
INSERT INTO
    recette_ingredient (
        recette_id,
        ingredient_id,
        quantite,
        unite_code
    )
VALUES (
        1,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lentilles'
        ),
        310.0,
        'pce'
    ),
    (
        1,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Amandes'
        ),
        520.0,
        'kg'
    ),
    (
        1,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chou-fleur'
        ),
        465.9,
        'ml'
    ),
    (
        1,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        211.0,
        'l'
    ),
    (
        1,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Gingembre'
        ),
        168.0,
        'pce'
    ),
    (
        1,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage râpé'
        ),
        176.9,
        'g'
    ),
    (
        2,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Seitan'
        ),
        273.0,
        'kg'
    ),
    (
        2,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Aubergine'
        ),
        214.0,
        'l'
    ),
    (
        2,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Betterave'
        ),
        460.0,
        'pce'
    ),
    (
        2,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de légumes'
        ),
        279.0,
        'l'
    ),
    (
        2,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage blanc'
        ),
        523.1,
        'ml'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Epinards'
        ),
        449.4,
        'ml'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Salade'
        ),
        238.0,
        'l'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Gingembre'
        ),
        302.0,
        'kg'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Champignon'
        ),
        84.5,
        'g'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tahini'
        ),
        206.0,
        'pce'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Romarin'
        ),
        525.8,
        'g'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sauce soja'
        ),
        69.0,
        'l'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Boeuf'
        ),
        19.0,
        'l'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sauce soja'
        ),
        287.0,
        'g'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        209.8,
        'ml'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Épeautre'
        ),
        393.0,
        'l'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Huile d''olive'
        ),
        512.9,
        'ml'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cumin'
        ),
        31.0,
        'pce'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Agneau'
        ),
        148.5,
        'g'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Flocons d''avoine'
        ),
        598.5,
        'ml'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fraises'
        ),
        266.0,
        'g'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        458.6,
        'g'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Piment'
        ),
        271.8,
        'g'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage blanc'
        ),
        543.0,
        'ml'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crevettes'
        ),
        221.5,
        'ml'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lardons'
        ),
        96.0,
        'l'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Riz'
        ),
        253.0,
        'pce'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lardons'
        ),
        413.0,
        'pce'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Banane'
        ),
        549.0,
        'l'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon fumé'
        ),
        147.0,
        'kg'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pomme'
        ),
        281.1,
        'ml'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        540.4,
        'g'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots rouges'
        ),
        542.0,
        'l'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        103.0,
        'pce'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cumin'
        ),
        568.0,
        'l'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron vert'
        ),
        127.5,
        'ml'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Orge'
        ),
        513.0,
        'l'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Moutarde'
        ),
        150.0,
        'g'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thé'
        ),
        222.0,
        'pce'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pois chiches'
        ),
        595.7,
        'ml'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Amandes'
        ),
        22.9,
        'ml'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        172.0,
        'l'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noix de cajou'
        ),
        501.0,
        'l'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        467.7,
        'ml'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Romarin'
        ),
        368.0,
        'kg'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mangue'
        ),
        139.2,
        'ml'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon'
        ),
        376.0,
        'kg'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage de chèvre'
        ),
        381.0,
        'kg'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Morue'
        ),
        192.3,
        'g'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poulet'
        ),
        202.8,
        'ml'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Betterave'
        ),
        114.0,
        'l'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Curry'
        ),
        474.0,
        'kg'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Myrtilles'
        ),
        323.2,
        'ml'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine'
        ),
        500.0,
        'ml'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème'
        ),
        549.3,
        'ml'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bacon'
        ),
        286.3,
        'g'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron rouge'
        ),
        93.0,
        'g'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mangue'
        ),
        517.0,
        'kg'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        581.0,
        'l'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thym'
        ),
        226.0,
        'pce'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jambon'
        ),
        18.0,
        'l'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Citron'
        ),
        495.0,
        'l'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Amandes'
        ),
        73.9,
        'ml'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Paprika'
        ),
        288.0,
        'kg'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        532.0,
        'pce'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mangue'
        ),
        204.0,
        'pce'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Quinoa'
        ),
        141.0,
        'pce'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Betterave'
        ),
        384.9,
        'g'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage de chèvre'
        ),
        37.0,
        'kg'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Café'
        ),
        189.6,
        'g'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron vert'
        ),
        79.0,
        'l'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Épeautre'
        ),
        533.0,
        'kg'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sauce soja'
        ),
        239.0,
        'kg'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Persil'
        ),
        405.6,
        'ml'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Café'
        ),
        396.0,
        'l'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Brocoli'
        ),
        373.0,
        'l'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mayonnaise'
        ),
        29.3,
        'ml'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Aubergine'
        ),
        138.2,
        'ml'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mangue'
        ),
        571.0,
        'l'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Myrtilles'
        ),
        68.6,
        'ml'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Huile d''olive'
        ),
        331.2,
        'ml'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        45.7,
        'ml'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage râpé'
        ),
        401.0,
        'g'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Citron'
        ),
        583.0,
        'pce'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        474.2,
        'g'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tofu'
        ),
        593.0,
        'kg'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Amandes'
        ),
        131.0,
        'pce'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thon'
        ),
        475.0,
        'kg'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Aubergine'
        ),
        12.0,
        'pce'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ail'
        ),
        593.0,
        'kg'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Steak haché'
        ),
        158.0,
        'pce'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        75.0,
        'kg'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Champignon'
        ),
        87.8,
        'g'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        476.1,
        'ml'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Aubergine'
        ),
        40.9,
        'ml'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crevettes'
        ),
        320.0,
        'l'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Carotte'
        ),
        291.0,
        'g'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pomme'
        ),
        312.8,
        'ml'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noix'
        ),
        36.0,
        'pce'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        188.0,
        'pce'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Courgette'
        ),
        45.9,
        'g'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        53.0,
        'l'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Vinaigre balsamique'
        ),
        200.0,
        'g'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Moutarde'
        ),
        49.0,
        'kg'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        378.3,
        'ml'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivre'
        ),
        334.0,
        'pce'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage blanc'
        ),
        234.7,
        'ml'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Courge'
        ),
        513.1,
        'g'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron rouge'
        ),
        435.0,
        'pce'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Amandes'
        ),
        264.0,
        'kg'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        254.0,
        'kg'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Morue'
        ),
        245.0,
        'l'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ketchup'
        ),
        194.4,
        'g'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sel'
        ),
        402.4,
        'ml'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Huile d''olive'
        ),
        500.7,
        'g'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        264.8,
        'g'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs séché 229'
        ),
        488.9,
        'ml'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre de cacahuète'
        ),
        45.0,
        'pce'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pâtes'
        ),
        341.0,
        'pce'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Citron'
        ),
        581.4,
        'g'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sauce soja'
        ),
        194.0,
        'pce'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Coriandre'
        ),
        351.0,
        'g'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        101.0,
        'kg'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de volaille'
        ),
        142.0,
        'l'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Kiwi'
        ),
        216.6,
        'g'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Moutarde'
        ),
        227.0,
        'pce'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Persil bio 760'
        ),
        348.7,
        'ml'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        25.0,
        'pce'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chou'
        ),
        27.1,
        'ml'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Curcuma'
        ),
        424.6,
        'ml'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Steak haché'
        ),
        553.7,
        'ml'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots blancs'
        ),
        13.6,
        'ml'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots rouges'
        ),
        344.0,
        'kg'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pâtes'
        ),
        137.0,
        'pce'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        278.0,
        'l'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ananas'
        ),
        228.0,
        'kg'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Orge'
        ),
        468.3,
        'ml'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oignon'
        ),
        362.0,
        'pce'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème'
        ),
        101.8,
        'g'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon'
        ),
        368.0,
        'l'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        171.0,
        'l'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        77.0,
        'pce'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Couscous'
        ),
        75.0,
        'l'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chapelure'
        ),
        297.0,
        'pce'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de légumes'
        ),
        36.8,
        'ml'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Moutarde'
        ),
        591.0,
        'l'
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tomate'
        ),
        463.0,
        'kg'
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thon'
        ),
        180.8,
        'ml'
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron vert'
        ),
        14.6,
        'g'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ketchup'
        ),
        502.0,
        'pce'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pomme'
        ),
        52.5,
        'ml'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine'
        ),
        267.4,
        'g'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cumin'
        ),
        553.0,
        'l'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Patate douce'
        ),
        349.7,
        'ml'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poire'
        ),
        249.0,
        'pce'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Champignon'
        ),
        181.0,
        'l'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        22.0,
        'l'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon fumé'
        ),
        62.0,
        'ml'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jambon'
        ),
        153.6,
        'g'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots blancs'
        ),
        246.0,
        'pce'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Amandes'
        ),
        243.5,
        'g'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tempeh'
        ),
        450.0,
        'ml'
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        384.0,
        'pce'
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Romarin'
        ),
        311.0,
        'pce'
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon fumé'
        ),
        217.1,
        'ml'
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre'
        ),
        149.0,
        'kg'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pois chiches'
        ),
        459.0,
        'kg'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Yaourt nature'
        ),
        114.5,
        'g'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pomme'
        ),
        284.0,
        'l'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Morue'
        ),
        458.0,
        'pce'
    );

-- Stocks for users
INSERT INTO
    stock (
        utilisateur_id,
        ingredient_id,
        quantite,
        unite_code,
        date_peremption
    )
VALUES (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        149.0,
        'l',
        '2025-11-13'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs séché 229'
        ),
        907.6,
        'ml',
        '2025-10-15'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de maïs'
        ),
        719.5,
        'ml',
        '2025-11-22'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Roquette'
        ),
        161.3,
        'ml',
        NULL
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Seigle'
        ),
        941.8,
        'g',
        '2025-12-04'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Orge'
        ),
        854.0,
        'pce',
        NULL
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots blancs'
        ),
        702.1,
        'g',
        NULL
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crevettes'
        ),
        516.0,
        'kg',
        '2025-10-25'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noix de cajou'
        ),
        703.3,
        'g',
        NULL
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Flocons d''avoine'
        ),
        1474.5,
        'ml',
        '2025-12-27'
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Agneau'
        ),
        107.0,
        'kg',
        NULL
    ),
    (
        3,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Huile d''olive'
        ),
        810.0,
        'l',
        NULL
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Paprika'
        ),
        145.6,
        'ml',
        '2025-12-31'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Persil bio 760'
        ),
        462.0,
        'l',
        NULL
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Concombre'
        ),
        1316.0,
        'pce',
        '2025-12-19'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Gingembre'
        ),
        1379.0,
        'kg',
        '2025-12-28'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sauce soja'
        ),
        237.0,
        'l',
        NULL
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Romarin'
        ),
        498.9,
        'g',
        '2026-01-15'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thym'
        ),
        1229.1,
        'ml',
        NULL
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        186.0,
        'pce',
        NULL
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sardines'
        ),
        575.0,
        'pce',
        '2025-10-29'
    ),
    (
        4,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon'
        ),
        546.0,
        'kg',
        NULL
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Courgette'
        ),
        1168.0,
        'pce',
        NULL
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        105.0,
        'pce',
        '2026-01-12'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Huile d''olive'
        ),
        240.0,
        'pce',
        '2025-10-26'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre'
        ),
        1255.0,
        'kg',
        NULL
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron rouge'
        ),
        1096.0,
        'kg',
        '2025-11-21'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        1456.0,
        'kg',
        NULL
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Origan'
        ),
        389.0,
        'l',
        '2026-01-17'
    ),
    (
        5,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sel'
        ),
        1361.0,
        'l',
        '2025-12-31'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noisettes'
        ),
        251.0,
        'pce',
        '2025-12-27'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Curcuma'
        ),
        1317.0,
        'l',
        NULL
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Concombre'
        ),
        1081.5,
        'g',
        '2025-10-21'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Romarin'
        ),
        171.6,
        'ml',
        '2025-12-02'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cumin'
        ),
        264.0,
        'pce',
        '2025-11-03'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        1333.0,
        'l',
        NULL
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Courge'
        ),
        127.0,
        'l',
        '2025-11-05'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mayonnaise'
        ),
        1492.0,
        'l',
        '2025-10-09'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pain'
        ),
        1399.7,
        'ml',
        NULL
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Steak haché'
        ),
        1197.5,
        'ml',
        '2025-11-11'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Yaourt nature'
        ),
        1059.0,
        'l',
        '2026-01-04'
    ),
    (
        6,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jambon'
        ),
        700.0,
        'l',
        '2025-10-16'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pois chiches'
        ),
        815.0,
        'pce',
        '2025-11-11'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ail'
        ),
        487.0,
        'kg',
        '2025-11-28'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tempeh'
        ),
        713.0,
        'pce',
        '2026-01-29'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Huile d''olive'
        ),
        915.0,
        'l',
        '2025-12-10'
    ),
    (
        7,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chou-fleur'
        ),
        401.0,
        'pce',
        '2025-11-29'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots rouges'
        ),
        1013.0,
        'kg',
        '2025-11-21'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Coriandre'
        ),
        1432.4,
        'g',
        '2026-01-14'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Epinards'
        ),
        854.0,
        'pce',
        '2025-12-05'
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Salade'
        ),
        971.7,
        'g',
        NULL
    ),
    (
        8,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mayonnaise'
        ),
        1133.6,
        'ml',
        '2025-10-14'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Epinards'
        ),
        114.0,
        'kg',
        '2026-01-18'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Myrtilles'
        ),
        1254.0,
        'kg',
        NULL
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de légumes'
        ),
        966.0,
        'l',
        NULL
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Flocons d''avoine'
        ),
        1088.3,
        'g',
        NULL
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivre'
        ),
        475.5,
        'g',
        '2025-10-31'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Curcuma'
        ),
        507.6,
        'g',
        '2025-11-25'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Betterave'
        ),
        736.0,
        'pce',
        '2025-12-27'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ananas'
        ),
        465.0,
        'kg',
        NULL
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Kiwi'
        ),
        1305.4,
        'g',
        '2025-10-21'
    ),
    (
        9,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        683.6,
        'ml',
        '2025-12-01'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thym'
        ),
        164.0,
        'l',
        NULL
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Banane'
        ),
        841.0,
        'kg',
        '2025-10-16'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Parmesan'
        ),
        1008.3,
        'ml',
        '2025-12-22'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thé'
        ),
        292.0,
        'l',
        '2025-12-02'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Paprika'
        ),
        1103.9,
        'g',
        NULL
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs séché 229'
        ),
        1497.0,
        'pce',
        '2026-01-15'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jambon'
        ),
        158.8,
        'g',
        NULL
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Olives'
        ),
        794.0,
        'ml',
        NULL
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Couscous'
        ),
        1432.0,
        'kg',
        '2025-12-22'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        100.0,
        'l',
        '2026-01-13'
    ),
    (
        10,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Myrtilles'
        ),
        575.1,
        'ml',
        NULL
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Morue'
        ),
        693.7,
        'ml',
        '2025-10-23'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Huile d''olive'
        ),
        582.0,
        'pce',
        '2025-11-10'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        1443.0,
        'kg',
        '2025-10-29'
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noix'
        ),
        801.0,
        'l',
        NULL
    ),
    (
        11,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Paprika'
        ),
        429.6,
        'g',
        '2025-12-02'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots rouges'
        ),
        705.5,
        'g',
        NULL
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Concombre'
        ),
        1496.0,
        'l',
        NULL
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thé'
        ),
        1018.4,
        'ml',
        NULL
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Persil bio 760'
        ),
        836.0,
        'pce',
        NULL
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage blanc'
        ),
        1082.0,
        'kg',
        NULL
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Yaourt nature'
        ),
        1201.0,
        'kg',
        '2025-10-21'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Citron'
        ),
        1198.0,
        'kg',
        '2025-12-08'
    ),
    (
        12,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        573.3,
        'g',
        NULL
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jambon'
        ),
        646.0,
        'pce',
        '2025-12-18'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chou-fleur'
        ),
        231.7,
        'g',
        '2025-10-15'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine'
        ),
        725.0,
        'l',
        '2025-10-22'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots rouges'
        ),
        978.0,
        'pce',
        '2025-10-22'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        779.0,
        'l',
        NULL
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème'
        ),
        801.2,
        'g',
        '2025-10-26'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pâtes'
        ),
        1405.4,
        'ml',
        '2025-12-11'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Dinde'
        ),
        1276.6,
        'ml',
        '2025-12-26'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Miel'
        ),
        448.0,
        'pce',
        NULL
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fraises'
        ),
        824.0,
        'pce',
        '2025-10-27'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Framboises'
        ),
        1415.0,
        'pce',
        '2025-12-29'
    ),
    (
        13,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait de coco'
        ),
        1095.0,
        'pce',
        NULL
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tofu'
        ),
        434.0,
        'pce',
        '2025-12-18'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noix de cajou'
        ),
        946.0,
        'l',
        '2026-01-27'
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oignon'
        ),
        470.0,
        'pce',
        NULL
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        405.0,
        'l',
        NULL
    ),
    (
        14,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Boeuf'
        ),
        481.0,
        'l',
        '2025-10-13'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chapelure'
        ),
        503.0,
        'kg',
        NULL
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mayonnaise'
        ),
        1464.3,
        'ml',
        '2025-11-22'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait de coco'
        ),
        864.0,
        'pce',
        '2025-12-04'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noisettes'
        ),
        437.8,
        'g',
        '2025-10-18'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thon'
        ),
        470.8,
        'g',
        '2025-12-23'
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thym'
        ),
        410.0,
        'l',
        NULL
    ),
    (
        15,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Morue'
        ),
        1230.0,
        'kg',
        NULL
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage râpé'
        ),
        783.0,
        'l',
        NULL
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Piment'
        ),
        896.0,
        'kg',
        '2025-11-11'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pain'
        ),
        916.0,
        'l',
        NULL
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Parmesan'
        ),
        464.0,
        'l',
        '2025-10-19'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Feta'
        ),
        244.0,
        'l',
        '2025-11-21'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noisettes'
        ),
        581.0,
        'l',
        '2025-12-17'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de maïs'
        ),
        332.0,
        'pce',
        NULL
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Dinde'
        ),
        610.2,
        'g',
        '2025-12-15'
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Carotte'
        ),
        1246.7,
        'ml',
        NULL
    ),
    (
        16,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème'
        ),
        222.0,
        'pce',
        NULL
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Paprika'
        ),
        108.0,
        'pce',
        '2026-01-05'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lardons'
        ),
        1215.8,
        'ml',
        '2025-10-25'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thym'
        ),
        1345.0,
        'pce',
        '2025-12-23'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chou'
        ),
        285.6,
        'ml',
        NULL
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Curry'
        ),
        910.9,
        'ml',
        '2025-12-10'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Kiwi'
        ),
        760.0,
        'pce',
        NULL
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        1233.0,
        'l',
        '2025-12-31'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Yaourt nature'
        ),
        1470.9,
        'g',
        NULL
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Morue'
        ),
        915.5,
        'g',
        '2025-12-28'
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Feta'
        ),
        888.0,
        'pce',
        NULL
    ),
    (
        17,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Vinaigre balsamique'
        ),
        747.0,
        'pce',
        '2026-01-06'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        657.2,
        'ml',
        '2025-11-01'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tofu'
        ),
        778.0,
        'l',
        NULL
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        1316.0,
        'l',
        NULL
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lentilles'
        ),
        1073.4,
        'g',
        '2025-12-16'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poulet'
        ),
        1497.3,
        'ml',
        '2025-11-23'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Salade'
        ),
        1437.2,
        'ml',
        '2025-12-13'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Café'
        ),
        842.1,
        'ml',
        NULL
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Persil'
        ),
        934.6,
        'ml',
        '2025-11-06'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage râpé'
        ),
        859.2,
        'ml',
        '2025-11-13'
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Carotte'
        ),
        1072.1,
        'ml',
        NULL
    ),
    (
        18,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chapelure'
        ),
        510.0,
        'l',
        '2026-01-15'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Concombre'
        ),
        1434.2,
        'ml',
        NULL
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Citron'
        ),
        111.0,
        'ml',
        NULL
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Salade'
        ),
        552.2,
        'g',
        '2025-11-07'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        360.0,
        'l',
        NULL
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Brocoli'
        ),
        1402.9,
        'ml',
        NULL
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cumin'
        ),
        208.0,
        'kg',
        NULL
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre clarifié'
        ),
        402.0,
        'kg',
        NULL
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Miel'
        ),
        377.0,
        'pce',
        '2025-10-18'
    ),
    (
        19,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Steak haché'
        ),
        529.0,
        'l',
        '2026-01-01'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tomate'
        ),
        742.0,
        'l',
        '2025-11-11'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Chou-fleur'
        ),
        463.9,
        'ml',
        '2026-01-12'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs séché 229'
        ),
        995.8,
        'g',
        '2026-01-08'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pain'
        ),
        1374.2,
        'g',
        '2026-01-26'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sauce soja'
        ),
        1404.0,
        'kg',
        '2026-01-21'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Épeautre'
        ),
        1193.0,
        'l',
        '2026-01-09'
    ),
    (
        20,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf en conserve 105'
        ),
        1321.3,
        'ml',
        '2025-12-17'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs séché 229'
        ),
        766.0,
        'pce',
        NULL
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        729.0,
        'pce',
        '2025-10-20'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Concombre'
        ),
        285.6,
        'ml',
        '2025-11-07'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Amandes'
        ),
        70.0,
        'kg',
        '2025-11-12'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Seigle'
        ),
        1028.0,
        'pce',
        '2025-12-23'
    ),
    (
        21,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Brocoli'
        ),
        1249.0,
        'l',
        '2025-10-17'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de volaille'
        ),
        698.0,
        'kg',
        '2025-11-17'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sel'
        ),
        894.6,
        'ml',
        NULL
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Banane'
        ),
        997.8,
        'ml',
        NULL
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        1018.3,
        'g',
        '2025-10-26'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait de coco'
        ),
        1045.0,
        'l',
        NULL
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crevettes'
        ),
        1050.9,
        'ml',
        NULL
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf en conserve 105'
        ),
        582.9,
        'ml',
        '2025-10-23'
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lentilles'
        ),
        272.0,
        'l',
        NULL
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tomate'
        ),
        592.0,
        'pce',
        NULL
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Quinoa'
        ),
        1148.0,
        'l',
        NULL
    ),
    (
        22,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Gingembre'
        ),
        1155.0,
        'kg',
        NULL
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Courge'
        ),
        213.0,
        'pce',
        NULL
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noix'
        ),
        343.0,
        'pce',
        '2025-10-27'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poire'
        ),
        1289.0,
        'ml',
        '2026-01-01'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Curry'
        ),
        1090.0,
        'kg',
        '2026-01-29'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre'
        ),
        696.0,
        'pce',
        '2025-10-22'
    ),
    (
        23,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Persil bio 760'
        ),
        652.0,
        'pce',
        NULL
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        115.7,
        'g',
        '2025-10-14'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bacon'
        ),
        1491.0,
        'pce',
        NULL
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Dinde'
        ),
        1479.9,
        'g',
        '2025-11-11'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Framboises'
        ),
        311.0,
        'l',
        '2025-12-27'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Carotte'
        ),
        593.0,
        'l',
        NULL
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Miel'
        ),
        1311.0,
        'l',
        NULL
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pois chiches'
        ),
        166.0,
        'l',
        NULL
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Steak haché'
        ),
        243.0,
        'pce',
        NULL
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tomate'
        ),
        308.8,
        'g',
        '2025-12-12'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mangue'
        ),
        1105.0,
        'kg',
        '2025-10-06'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ail'
        ),
        1468.8,
        'g',
        '2026-01-06'
    ),
    (
        24,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Betterave'
        ),
        665.0,
        'pce',
        '2025-11-04'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Amandes'
        ),
        96.7,
        'g',
        NULL
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Basilic'
        ),
        1161.0,
        'pce',
        NULL
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Huile d''olive'
        ),
        399.0,
        'g',
        '2025-12-21'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs'
        ),
        697.3,
        'g',
        NULL
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage râpé'
        ),
        404.9,
        'g',
        '2025-12-01'
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf en conserve 105'
        ),
        833.0,
        'kg',
        NULL
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de maïs'
        ),
        253.2,
        'g',
        NULL
    ),
    (
        25,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Framboises'
        ),
        1233.0,
        'kg',
        NULL
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Salade'
        ),
        371.0,
        'pce',
        '2025-10-13'
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sardines'
        ),
        1425.0,
        'pce',
        NULL
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Curcuma'
        ),
        958.0,
        'kg',
        '2025-12-08'
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        1459.8,
        'g',
        NULL
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Steak haché'
        ),
        1189.0,
        'l',
        '2025-11-28'
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crevettes'
        ),
        266.0,
        'l',
        '2026-01-10'
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Epinards'
        ),
        737.0,
        'pce',
        NULL
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron vert'
        ),
        1293.4,
        'ml',
        '2025-12-04'
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de maïs'
        ),
        865.5,
        'g',
        NULL
    ),
    (
        26,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        818.0,
        'pce',
        '2025-11-07'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        1101.0,
        'pce',
        '2025-11-09'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Seigle'
        ),
        1027.0,
        'l',
        NULL
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        322.8,
        'g',
        NULL
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs séché 229'
        ),
        365.0,
        'pce',
        '2025-11-17'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noix'
        ),
        1437.7,
        'ml',
        '2025-10-30'
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        1133.0,
        'g',
        NULL
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Paprika'
        ),
        1059.0,
        'kg',
        NULL
    ),
    (
        27,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème'
        ),
        1377.0,
        'l',
        NULL
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cumin'
        ),
        726.0,
        'l',
        NULL
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Noisettes'
        ),
        1154.0,
        'l',
        '2025-11-01'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Patate douce'
        ),
        503.7,
        'ml',
        '2026-01-24'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Épeautre'
        ),
        1125.0,
        'kg',
        '2025-12-15'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Coriandre'
        ),
        890.0,
        'pce',
        '2025-10-25'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Dinde'
        ),
        528.0,
        'kg',
        '2026-01-20'
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Quinoa'
        ),
        774.0,
        'kg',
        NULL
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Curry'
        ),
        423.1,
        'ml',
        NULL
    ),
    (
        28,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Feta'
        ),
        718.0,
        'l',
        NULL
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Saumon fumé'
        ),
        99.0,
        'pce',
        NULL
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        1158.3,
        'g',
        '2026-01-21'
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Framboises'
        ),
        149.0,
        'kg',
        '2025-11-02'
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Brocoli'
        ),
        711.0,
        'pce',
        '2025-12-26'
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fromage blanc'
        ),
        1373.0,
        'pce',
        NULL
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Banane'
        ),
        59.6,
        'g',
        NULL
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Persil bio 760'
        ),
        74.3,
        'g',
        NULL
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        1467.0,
        'pce',
        '2026-01-18'
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Seigle'
        ),
        1219.0,
        'l',
        NULL
    ),
    (
        29,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Riz'
        ),
        1381.2,
        'g',
        '2025-11-05'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Haricots blancs'
        ),
        590.9,
        'g',
        '2025-12-17'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Courge'
        ),
        1486.0,
        'kg',
        '2026-01-01'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pois chiches'
        ),
        997.9,
        'g',
        NULL
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Steak haché'
        ),
        185.6,
        'g',
        '2025-12-15'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Coriandre'
        ),
        131.0,
        'l',
        '2025-10-27'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Couscous'
        ),
        774.8,
        'g',
        '2026-01-14'
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lardons'
        ),
        870.5,
        'ml',
        NULL
    ),
    (
        30,
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Miel'
        ),
        1347.4,
        'g',
        NULL
    );

-- Price history (subset)
INSERT INTO
    prix_ingredient (
        ingredient_id,
        date_effet,
        prix_unitaire
    )
VALUES (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Champignon'
        ),
        '2025-06-01',
        9.2
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Champignon'
        ),
        '2025-07-01',
        4.8
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Champignon'
        ),
        '2025-07-31',
        2.07
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Champignon'
        ),
        '2025-08-30',
        3.55
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ail'
        ),
        '2025-06-01',
        1.84
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ail'
        ),
        '2025-07-01',
        7.66
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ail'
        ),
        '2025-07-31',
        7.75
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Ail'
        ),
        '2025-08-30',
        7.55
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème soja'
        ),
        '2025-06-01',
        11.66
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème soja'
        ),
        '2025-07-01',
        4.59
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème soja'
        ),
        '2025-07-31',
        7.98
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Crème soja'
        ),
        '2025-08-30',
        9.62
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        '2025-06-01',
        5.96
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        '2025-07-01',
        3.51
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        '2025-07-31',
        7.08
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de blé'
        ),
        '2025-08-30',
        5.13
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thé'
        ),
        '2025-06-01',
        3.04
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thé'
        ),
        '2025-07-01',
        7.44
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thé'
        ),
        '2025-07-31',
        5.18
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thé'
        ),
        '2025-08-30',
        9.49
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        '2025-06-01',
        4.25
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        '2025-07-01',
        3.71
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        '2025-07-31',
        1.81
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Farine de riz'
        ),
        '2025-08-30',
        3.95
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Roquette'
        ),
        '2025-06-01',
        5.18
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Roquette'
        ),
        '2025-07-01',
        9.62
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Roquette'
        ),
        '2025-07-31',
        2.7
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Roquette'
        ),
        '2025-08-30',
        5.29
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre de cacahuète'
        ),
        '2025-06-01',
        4.97
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre de cacahuète'
        ),
        '2025-07-01',
        2.01
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre de cacahuète'
        ),
        '2025-07-31',
        11.37
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre de cacahuète'
        ),
        '2025-08-30',
        5.89
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Couscous'
        ),
        '2025-06-01',
        9.37
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Couscous'
        ),
        '2025-07-01',
        2.12
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Couscous'
        ),
        '2025-07-31',
        1.96
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Couscous'
        ),
        '2025-08-30',
        5.74
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Boeuf'
        ),
        '2025-06-01',
        7.13
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Boeuf'
        ),
        '2025-07-01',
        6.64
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Boeuf'
        ),
        '2025-07-31',
        2.14
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Boeuf'
        ),
        '2025-08-30',
        1.99
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre'
        ),
        '2025-06-01',
        7.1
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre'
        ),
        '2025-07-01',
        7.57
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre'
        ),
        '2025-07-31',
        9.63
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre'
        ),
        '2025-08-30',
        10.5
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        '2025-06-01',
        1.14
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        '2025-07-01',
        5.55
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        '2025-07-31',
        9.57
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Jus d''orange'
        ),
        '2025-08-30',
        8.97
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs'
        ),
        '2025-06-01',
        7.15
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs'
        ),
        '2025-07-01',
        11.92
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs'
        ),
        '2025-07-31',
        3.67
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Maïs'
        ),
        '2025-08-30',
        6.73
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Brocoli'
        ),
        '2025-06-01',
        8.54
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Brocoli'
        ),
        '2025-07-01',
        2.86
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Brocoli'
        ),
        '2025-07-31',
        3.96
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Brocoli'
        ),
        '2025-08-30',
        3.95
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre clarifié'
        ),
        '2025-06-01',
        2.61
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre clarifié'
        ),
        '2025-07-01',
        2.84
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre clarifié'
        ),
        '2025-07-31',
        4.04
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Beurre clarifié'
        ),
        '2025-08-30',
        4.3
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de légumes'
        ),
        '2025-06-01',
        9.61
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de légumes'
        ),
        '2025-07-01',
        4.97
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de légumes'
        ),
        '2025-07-31',
        11.39
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Bouillon de légumes'
        ),
        '2025-08-30',
        8.93
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poulet'
        ),
        '2025-06-01',
        6.45
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poulet'
        ),
        '2025-07-01',
        7.78
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poulet'
        ),
        '2025-07-31',
        6.04
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poulet'
        ),
        '2025-08-30',
        2.49
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pomme'
        ),
        '2025-06-01',
        1.07
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pomme'
        ),
        '2025-07-01',
        5.35
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pomme'
        ),
        '2025-07-31',
        10.26
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pomme'
        ),
        '2025-08-30',
        5.18
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Agneau'
        ),
        '2025-06-01',
        10.48
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Agneau'
        ),
        '2025-07-01',
        5.84
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Agneau'
        ),
        '2025-07-31',
        5.74
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Agneau'
        ),
        '2025-08-30',
        10.06
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Carotte'
        ),
        '2025-06-01',
        8.16
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Carotte'
        ),
        '2025-07-01',
        7.54
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Carotte'
        ),
        '2025-07-31',
        4.3
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Carotte'
        ),
        '2025-08-30',
        7.64
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thon'
        ),
        '2025-06-01',
        8.65
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thon'
        ),
        '2025-07-01',
        6.27
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thon'
        ),
        '2025-07-31',
        2.95
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Thon'
        ),
        '2025-08-30',
        5.38
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Aubergine'
        ),
        '2025-06-01',
        4.51
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Aubergine'
        ),
        '2025-07-01',
        9.08
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Aubergine'
        ),
        '2025-07-31',
        7.96
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Aubergine'
        ),
        '2025-08-30',
        11.65
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        '2025-06-01',
        9.6
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        '2025-07-01',
        4.58
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        '2025-07-31',
        4.08
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Sucre'
        ),
        '2025-08-30',
        9.64
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Kiwi'
        ),
        '2025-06-01',
        5.02
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Kiwi'
        ),
        '2025-07-01',
        11.25
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Kiwi'
        ),
        '2025-07-31',
        3.2
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Kiwi'
        ),
        '2025-08-30',
        11.97
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fraises'
        ),
        '2025-06-01',
        2.98
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fraises'
        ),
        '2025-07-01',
        9.44
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fraises'
        ),
        '2025-07-31',
        1.3
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Fraises'
        ),
        '2025-08-30',
        9.0
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Miel'
        ),
        '2025-06-01',
        11.37
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Miel'
        ),
        '2025-07-01',
        3.31
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Miel'
        ),
        '2025-07-31',
        9.77
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Miel'
        ),
        '2025-08-30',
        10.14
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tahini'
        ),
        '2025-06-01',
        1.76
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tahini'
        ),
        '2025-07-01',
        10.33
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tahini'
        ),
        '2025-07-31',
        9.75
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tahini'
        ),
        '2025-08-30',
        8.4
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron vert'
        ),
        '2025-06-01',
        2.53
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron vert'
        ),
        '2025-07-01',
        4.33
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron vert'
        ),
        '2025-07-31',
        3.78
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poivron vert'
        ),
        '2025-08-30',
        2.7
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pain'
        ),
        '2025-06-01',
        5.65
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pain'
        ),
        '2025-07-01',
        5.15
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pain'
        ),
        '2025-07-31',
        5.94
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Pain'
        ),
        '2025-08-30',
        7.58
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tofu'
        ),
        '2025-06-01',
        7.4
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tofu'
        ),
        '2025-07-01',
        6.88
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tofu'
        ),
        '2025-07-31',
        11.16
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tofu'
        ),
        '2025-08-30',
        10.57
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Epinards'
        ),
        '2025-06-01',
        5.6
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Epinards'
        ),
        '2025-07-01',
        1.4
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Epinards'
        ),
        '2025-07-31',
        11.65
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Epinards'
        ),
        '2025-08-30',
        8.72
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poire'
        ),
        '2025-06-01',
        9.94
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poire'
        ),
        '2025-07-01',
        7.53
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poire'
        ),
        '2025-07-31',
        11.06
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Poire'
        ),
        '2025-08-30',
        2.2
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Gingembre'
        ),
        '2025-06-01',
        3.73
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Gingembre'
        ),
        '2025-07-01',
        8.31
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Gingembre'
        ),
        '2025-07-31',
        2.83
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Gingembre'
        ),
        '2025-08-30',
        7.74
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        '2025-06-01',
        7.2
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        '2025-07-01',
        8.1
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        '2025-07-31',
        8.11
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Eau'
        ),
        '2025-08-30',
        11.63
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tempeh'
        ),
        '2025-06-01',
        4.65
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tempeh'
        ),
        '2025-07-01',
        9.76
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tempeh'
        ),
        '2025-07-31',
        2.17
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Tempeh'
        ),
        '2025-08-30',
        2.08
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        '2025-06-01',
        3.44
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        '2025-07-01',
        9.22
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        '2025-07-31',
        7.14
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Cabillaud'
        ),
        '2025-08-30',
        8.56
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        '2025-06-01',
        3.43
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        '2025-07-01',
        5.12
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        '2025-07-31',
        6.09
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Graines de sésame'
        ),
        '2025-08-30',
        8.48
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        '2025-06-01',
        8.59
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        '2025-07-01',
        2.66
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        '2025-07-31',
        11.97
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Oeuf'
        ),
        '2025-08-30',
        6.31
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        '2025-06-01',
        4.25
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        '2025-07-01',
        11.13
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        '2025-07-31',
        1.94
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Lait'
        ),
        '2025-08-30',
        10.14
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        '2025-06-01',
        9.03
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        '2025-07-01',
        4.83
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        '2025-07-31',
        4.77
    ),
    (
        (
            SELECT id
            FROM ingredient
            WHERE
                nom = 'Mozzarella'
        ),
        '2025-08-30',
        9.63
    )
ON DUPLICATE KEY UPDATE
    prix_unitaire = VALUES(prix_unitaire);

-- Avis (ratings)
INSERT IGNORE INTO
    avis (
        utilisateur_id,
        recette_id,
        note,
        commentaire
    )
VALUES (
        3,
        16,
        5,
        'Auto-generated review'
    ),
    (
        3,
        12,
        4,
        'Auto-generated review'
    ),
    (
        3,
        30,
        4,
        'Auto-generated review'
    ),
    (
        3,
        4,
        3,
        'Auto-generated review'
    ),
    (
        3,
        15,
        4,
        'Auto-generated review'
    ),
    (
        3,
        24,
        3,
        'Auto-generated review'
    ),
    (
        4,
        23,
        5,
        'Auto-generated review'
    ),
    (
        4,
        4,
        3,
        'Auto-generated review'
    ),
    (
        4,
        1,
        5,
        'Auto-generated review'
    ),
    (
        4,
        11,
        3,
        'Auto-generated review'
    ),
    (
        4,
        21,
        5,
        'Auto-generated review'
    ),
    (
        4,
        29,
        3,
        'Auto-generated review'
    ),
    (
        4,
        22,
        4,
        'Auto-generated review'
    ),
    (
        4,
        6,
        5,
        'Auto-generated review'
    ),
    (
        5,
        15,
        3,
        'Auto-generated review'
    ),
    (
        5,
        8,
        3,
        'Auto-generated review'
    ),
    (
        5,
        26,
        5,
        'Auto-generated review'
    ),
    (
        5,
        13,
        5,
        'Auto-generated review'
    ),
    (
        5,
        21,
        4,
        'Auto-generated review'
    ),
    (
        6,
        1,
        4,
        'Auto-generated review'
    ),
    (
        6,
        24,
        5,
        'Auto-generated review'
    ),
    (
        6,
        20,
        4,
        'Auto-generated review'
    ),
    (
        6,
        29,
        4,
        'Auto-generated review'
    ),
    (
        6,
        7,
        3,
        'Auto-generated review'
    ),
    (
        7,
        7,
        3,
        'Auto-generated review'
    ),
    (
        7,
        30,
        5,
        'Auto-generated review'
    ),
    (
        7,
        9,
        3,
        'Auto-generated review'
    ),
    (
        7,
        25,
        4,
        'Auto-generated review'
    ),
    (
        7,
        23,
        4,
        'Auto-generated review'
    ),
    (
        7,
        3,
        3,
        'Auto-generated review'
    ),
    (
        7,
        19,
        4,
        'Auto-generated review'
    ),
    (
        8,
        9,
        4,
        'Auto-generated review'
    ),
    (
        8,
        22,
        5,
        'Auto-generated review'
    ),
    (
        9,
        11,
        4,
        'Auto-generated review'
    ),
    (
        9,
        20,
        4,
        'Auto-generated review'
    ),
    (
        9,
        13,
        4,
        'Auto-generated review'
    ),
    (
        9,
        29,
        5,
        'Auto-generated review'
    ),
    (
        9,
        28,
        3,
        'Auto-generated review'
    ),
    (
        9,
        19,
        5,
        'Auto-generated review'
    ),
    (
        9,
        4,
        5,
        'Auto-generated review'
    ),
    (
        10,
        10,
        3,
        'Auto-generated review'
    ),
    (
        10,
        20,
        4,
        'Auto-generated review'
    ),
    (
        10,
        19,
        3,
        'Auto-generated review'
    ),
    (
        10,
        3,
        3,
        'Auto-generated review'
    ),
    (
        10,
        22,
        4,
        'Auto-generated review'
    ),
    (
        10,
        5,
        5,
        'Auto-generated review'
    ),
    (
        10,
        11,
        3,
        'Auto-generated review'
    ),
    (
        10,
        4,
        5,
        'Auto-generated review'
    ),
    (
        11,
        14,
        4,
        'Auto-generated review'
    ),
    (
        11,
        20,
        3,
        'Auto-generated review'
    ),
    (
        11,
        5,
        4,
        'Auto-generated review'
    ),
    (
        11,
        19,
        5,
        'Auto-generated review'
    ),
    (
        11,
        13,
        5,
        'Auto-generated review'
    ),
    (
        12,
        30,
        3,
        'Auto-generated review'
    ),
    (
        12,
        21,
        3,
        'Auto-generated review'
    ),
    (
        12,
        6,
        4,
        'Auto-generated review'
    ),
    (
        12,
        18,
        4,
        'Auto-generated review'
    ),
    (
        12,
        28,
        5,
        'Auto-generated review'
    ),
    (
        12,
        16,
        3,
        'Auto-generated review'
    ),
    (
        12,
        10,
        4,
        'Auto-generated review'
    ),
    (
        13,
        16,
        3,
        'Auto-generated review'
    ),
    (
        13,
        5,
        4,
        'Auto-generated review'
    ),
    (
        14,
        17,
        4,
        'Auto-generated review'
    ),
    (
        14,
        21,
        5,
        'Auto-generated review'
    ),
    (
        14,
        16,
        4,
        'Auto-generated review'
    ),
    (
        14,
        14,
        4,
        'Auto-generated review'
    ),
    (
        14,
        22,
        3,
        'Auto-generated review'
    ),
    (
        14,
        28,
        3,
        'Auto-generated review'
    ),
    (
        15,
        1,
        4,
        'Auto-generated review'
    ),
    (
        15,
        26,
        3,
        'Auto-generated review'
    ),
    (
        15,
        25,
        5,
        'Auto-generated review'
    ),
    (
        15,
        8,
        4,
        'Auto-generated review'
    ),
    (
        15,
        10,
        3,
        'Auto-generated review'
    ),
    (
        15,
        2,
        4,
        'Auto-generated review'
    ),
    (
        16,
        24,
        3,
        'Auto-generated review'
    ),
    (
        16,
        25,
        5,
        'Auto-generated review'
    ),
    (
        16,
        29,
        3,
        'Auto-generated review'
    ),
    (
        16,
        16,
        4,
        'Auto-generated review'
    ),
    (
        16,
        18,
        5,
        'Auto-generated review'
    ),
    (
        16,
        17,
        4,
        'Auto-generated review'
    ),
    (
        17,
        27,
        5,
        'Auto-generated review'
    ),
    (
        17,
        25,
        3,
        'Auto-generated review'
    ),
    (
        17,
        2,
        4,
        'Auto-generated review'
    ),
    (
        17,
        29,
        3,
        'Auto-generated review'
    ),
    (
        17,
        24,
        5,
        'Auto-generated review'
    ),
    (
        17,
        15,
        5,
        'Auto-generated review'
    ),
    (
        18,
        8,
        4,
        'Auto-generated review'
    ),
    (
        18,
        10,
        3,
        'Auto-generated review'
    ),
    (
        18,
        28,
        3,
        'Auto-generated review'
    ),
    (
        18,
        2,
        3,
        'Auto-generated review'
    ),
    (
        18,
        15,
        5,
        'Auto-generated review'
    ),
    (
        18,
        9,
        5,
        'Auto-generated review'
    ),
    (
        18,
        12,
        5,
        'Auto-generated review'
    ),
    (
        18,
        3,
        4,
        'Auto-generated review'
    ),
    (
        19,
        23,
        3,
        'Auto-generated review'
    ),
    (
        19,
        20,
        3,
        'Auto-generated review'
    ),
    (
        19,
        21,
        5,
        'Auto-generated review'
    ),
    (
        19,
        14,
        4,
        'Auto-generated review'
    ),
    (
        19,
        6,
        5,
        'Auto-generated review'
    ),
    (
        19,
        29,
        4,
        'Auto-generated review'
    ),
    (
        19,
        5,
        5,
        'Auto-generated review'
    ),
    (
        19,
        7,
        5,
        'Auto-generated review'
    ),
    (
        20,
        11,
        4,
        'Auto-generated review'
    ),
    (
        20,
        23,
        5,
        'Auto-generated review'
    ),
    (
        20,
        10,
        4,
        'Auto-generated review'
    ),
    (
        21,
        17,
        4,
        'Auto-generated review'
    ),
    (
        21,
        29,
        5,
        'Auto-generated review'
    ),
    (
        21,
        22,
        3,
        'Auto-generated review'
    ),
    (
        21,
        27,
        5,
        'Auto-generated review'
    ),
    (
        21,
        4,
        3,
        'Auto-generated review'
    ),
    (
        21,
        5,
        3,
        'Auto-generated review'
    ),
    (
        21,
        14,
        3,
        'Auto-generated review'
    ),
    (
        21,
        2,
        5,
        'Auto-generated review'
    ),
    (
        22,
        27,
        4,
        'Auto-generated review'
    ),
    (
        22,
        8,
        4,
        'Auto-generated review'
    ),
    (
        22,
        25,
        3,
        'Auto-generated review'
    ),
    (
        22,
        22,
        5,
        'Auto-generated review'
    ),
    (
        23,
        9,
        3,
        'Auto-generated review'
    ),
    (
        23,
        21,
        4,
        'Auto-generated review'
    ),
    (
        23,
        14,
        5,
        'Auto-generated review'
    ),
    (
        23,
        13,
        5,
        'Auto-generated review'
    ),
    (
        23,
        15,
        4,
        'Auto-generated review'
    ),
    (
        23,
        3,
        5,
        'Auto-generated review'
    ),
    (
        23,
        29,
        4,
        'Auto-generated review'
    ),
    (
        24,
        16,
        5,
        'Auto-generated review'
    ),
    (
        24,
        11,
        3,
        'Auto-generated review'
    ),
    (
        24,
        19,
        5,
        'Auto-generated review'
    ),
    (
        24,
        1,
        4,
        'Auto-generated review'
    ),
    (
        24,
        28,
        5,
        'Auto-generated review'
    ),
    (
        25,
        23,
        3,
        'Auto-generated review'
    ),
    (
        25,
        12,
        4,
        'Auto-generated review'
    ),
    (
        25,
        28,
        3,
        'Auto-generated review'
    ),
    (
        25,
        3,
        4,
        'Auto-generated review'
    ),
    (
        25,
        26,
        4,
        'Auto-generated review'
    ),
    (
        25,
        18,
        4,
        'Auto-generated review'
    ),
    (
        25,
        13,
        4,
        'Auto-generated review'
    ),
    (
        26,
        18,
        4,
        'Auto-generated review'
    ),
    (
        26,
        19,
        4,
        'Auto-generated review'
    ),
    (
        26,
        5,
        5,
        'Auto-generated review'
    ),
    (
        26,
        28,
        3,
        'Auto-generated review'
    ),
    (
        27,
        4,
        4,
        'Auto-generated review'
    ),
    (
        27,
        21,
        3,
        'Auto-generated review'
    ),
    (
        28,
        30,
        3,
        'Auto-generated review'
    ),
    (
        28,
        28,
        4,
        'Auto-generated review'
    ),
    (
        29,
        1,
        3,
        'Auto-generated review'
    ),
    (
        29,
        14,
        5,
        'Auto-generated review'
    ),
    (
        29,
        7,
        4,
        'Auto-generated review'
    ),
    (
        29,
        23,
        3,
        'Auto-generated review'
    ),
    (
        29,
        30,
        4,
        'Auto-generated review'
    ),
    (
        30,
        21,
        4,
        'Auto-generated review'
    ),
    (
        30,
        12,
        3,
        'Auto-generated review'
    );

-- Historique de cuisson
INSERT INTO
    historique_cuisson (
        utilisateur_id,
        recette_id,
        personnes
    )
VALUES (3, 22, 2),
    (3, 29, 1),
    (3, 21, 4),
    (4, 24, 2),
    (4, 23, 4),
    (4, 25, 1),
    (5, 1, 2),
    (6, 3, 4),
    (6, 5, 1),
    (6, 19, 1),
    (6, 8, 2),
    (7, 28, 4),
    (8, 16, 2),
    (8, 3, 4),
    (9, 24, 1),
    (10, 11, 2),
    (11, 5, 2),
    (11, 13, 2),
    (11, 25, 1),
    (12, 20, 2),
    (13, 12, 2),
    (13, 24, 4),
    (13, 7, 4),
    (13, 21, 2),
    (14, 29, 1),
    (15, 25, 4),
    (15, 4, 2),
    (16, 11, 2),
    (16, 26, 1),
    (16, 5, 2),
    (16, 8, 2),
    (17, 28, 2),
    (18, 17, 2),
    (18, 20, 4),
    (19, 21, 2),
    (19, 2, 4),
    (19, 26, 4),
    (20, 8, 4),
    (21, 17, 1),
    (22, 30, 4),
    (22, 11, 4),
    (22, 5, 2),
    (23, 25, 1),
    (23, 16, 1),
    (24, 1, 2),
    (25, 2, 1),
    (25, 30, 4),
    (26, 21, 4),
    (26, 23, 4),
    (26, 17, 4),
    (27, 21, 2),
    (28, 3, 2),
    (28, 10, 2),
    (28, 17, 2),
    (29, 19, 1),
    (29, 21, 2),
    (29, 25, 4),
    (29, 27, 2),
    (30, 8, 1);

-- ==========================================================
-- Étape 4 : Création des vues, procédure et triggers
-- ==========================================================

DROP VIEW IF EXISTS v_recette_note;

DROP VIEW IF EXISTS v_prix_courant;

DROP VIEW IF EXISTS v_cout_recette;

DROP PROCEDURE IF EXISTS sp_cuire_recette;

DROP TRIGGER IF EXISTS trg_stock_ai;

DROP TRIGGER IF EXISTS trg_stock_au;

-- === Vues ===
CREATE OR REPLACE VIEW v_recette_note AS
SELECT
    r.id AS recette_id,
    COUNT(a.id) AS nb_avis,
    IFNULL(AVG(a.note), 0) AS note_moy
FROM recette r
    LEFT JOIN avis a ON a.recette_id = r.id
GROUP BY
    r.id;

CREATE OR REPLACE VIEW v_prix_courant AS
SELECT p1.ingredient_id, p1.prix_unitaire
FROM prix_ingredient p1
    JOIN (
        SELECT ingredient_id, MAX(date_effet) max_date
        FROM prix_ingredient
        GROUP BY
            ingredient_id
    ) t ON t.ingredient_id = p1.ingredient_id
    AND t.max_date = p1.date_effet;

CREATE OR REPLACE VIEW v_cout_recette AS
SELECT ri.recette_id, SUM(
        ri.quantite * IFNULL(vp.prix_unitaire, i.prix_ref)
    ) AS cout_estime
FROM
    recette_ingredient ri
    JOIN ingredient i ON i.id = ri.ingredient_id
    LEFT JOIN v_prix_courant vp ON vp.ingredient_id = i.id
GROUP BY
    ri.recette_id;

-- === Procédure ===
DELIMITER $$

CREATE PROCEDURE sp_cuire_recette(
    IN p_utilisateur INT,
    IN p_recette INT,
    IN p_personnes TINYINT
)
BEGIN
    DECLARE def_personnes TINYINT;
    SELECT personnes_defaut INTO def_personnes FROM recette WHERE id = p_recette;
    INSERT INTO historique_cuisson(utilisateur_id, recette_id, personnes)
    VALUES (p_utilisateur, p_recette, p_personnes);
    UPDATE stock s
        JOIN (
            SELECT ri.ingredient_id, ri.unite_code,
                   SUM(ri.quantite * p_personnes / def_personnes) AS conso
            FROM recette_ingredient ri
            WHERE ri.recette_id = p_recette
            GROUP BY ri.ingredient_id, ri.unite_code
        ) x ON s.ingredient_id = x.ingredient_id
    SET s.quantite = GREATEST(0, s.quantite - x.conso)
    WHERE s.utilisateur_id = p_utilisateur;
END$$

DELIMITER;

-- === Triggers ===
DELIMITER $$

CREATE TRIGGER trg_stock_ai AFTER INSERT ON stock
    FOR EACH ROW
    INSERT INTO mvt_stock(utilisateur_id, ingredient_id, delta, unite_code, raison)
    VALUES (NEW.utilisateur_id, NEW.ingredient_id, NEW.quantite, NEW.unite_code, 'ajout');
$$

CREATE TRIGGER trg_stock_au AFTER UPDATE ON stock
    FOR EACH ROW
    INSERT INTO mvt_stock(utilisateur_id, ingredient_id, delta, unite_code, raison)
    VALUES (NEW.utilisateur_id, NEW.ingredient_id, NEW.quantite - OLD.quantite, NEW.unite_code, 'correction');
$$

DELIMITER;

-- ==========================================================
-- Étape 5 : Vérifications & statistiques
-- ==========================================================
SELECT COUNT(*) AS nb_utilisateurs FROM utilisateur;

SELECT COUNT(*) AS nb_recettes FROM recette;

SELECT COUNT(*) AS nb_ingredients FROM ingredient;

SELECT COUNT(*) AS nb_avis FROM avis;

SELECT titre, COUNT(ri.ingredient_id) AS nb_ingr
FROM
    recette r
    JOIN recette_ingredient ri ON ri.recette_id = r.id
GROUP BY
    r.id
ORDER BY nb_ingr DESC
LIMIT 10;

SELECT r.titre, v.note_moy
FROM v_recette_note v
    JOIN recette r ON r.id = v.recette_id
ORDER BY v.note_moy DESC
LIMIT 10;