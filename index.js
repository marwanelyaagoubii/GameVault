require('dotenv').config();
const dbHost = process.env.DB_HOST;
const dbUser = process.env.DB_USER;
const dbPassword = process.env.DB_PASSWORD;
const dbName = process.env.DB_NAME;

const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt'); // Pour hacher les mots de passe
const app = express();
const port = 3000;

// Middleware pour parser le body des requêtes en JSON
app.use(bodyParser.json());

// Configuration de la connexion à MySQL
const db = mysql.createConnection({
    host: dbHost, // Remplacez par l'IP de votre serveur MySQL
    user: dbUser, // Nom d'utilisateur de la base de données
    password: dbPassword, // Mot de passe de la base de données
    database: dbName // Nom de la base de données
});

// Connexion à MySQL
db.connect((err) => {
    if (err) {
        console.error('Erreur de connexion à MySQL:', err);
        return;
    }
    console.log('Connecté à la base de données MySQL');
    console.log(`Connecté vous à PHPMyAdmin http:///10.50.0.26/phpmyadmin `);
});


app.post('/inscrire', async(req, res) => {
    const { nom, prenom, email, password } = req.body;

    try {
        const hashedPassword = await bcrypt.hash(password, 10);

        const sql = 'INSERT INTO `utilisateur` (nom, prenom, email, password) VALUES (?, ?, ?, ?)';
        db.query(sql, [nom, prenom, email, hashedPassword], (err, result) => {
            if (err) {
                return res.status(500).send(err);
            }
            res.json({
                id: result.insertId,
                nom,
                prenom,
                email
            });
        });
    } catch (err) {
        res.status(500).send('Erreur lors du hashage du mot de passe');
    }
});

app.get('/user', (req, res) => {
    const sql = 'SELECT * FROM utilisateur';
    db.query(sql, (err, results) => {
        if (err) {
            return res.status(500).send(err);
        }
        res.json(results);
    });
});

app.post('/connexion', async(req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: '12345689' });
    }
    const sql = 'SELECT * FROM `utilisateur` WHERE email = ?';
    db.query(sql, [email], async(err, results) => {
        if (err) {
            return res.status(500).send(err);
        }
        if (results.length === 0) {
            return res.status(401).json({ message: 'Emailt de passe incorrect' });
        }

        const utilisateur = results[0];

        bcrypt.compare(password, utilisateur.password, (err, result) => {
            if (err) {
                return res.status(500).send(err);
            }
            if (!result) {
                return res.status(401).json({ message: 'email ou mdp incorrect' });
            }

            res.json({ message: 'Connexion reussite', utilisateur });
        });
    });
});

// gestion des catalogues des jeux vidéo-

// Ajouter un jeu
app.post('/ajouterJeu', async(req, res) => {
    console.log('test');
    const { titre, plateforme, prix, quantites, genre, image } = req.body; // Remplacement de description par genre
    try {
        console.log('Données reçues : Titre -', titre, ', Plateforme -', plateforme, ', Prix -', prix, ', Quantites -', quantites, ', Genre -', genre, ', Image -', image);

        const sql = 'INSERT INTO jeux (titre, plateforme, prix, quantites, genre, image) VALUES (?, ?, ?, ?, ?, ?)'; // Remplacer description par genre
        db.query(sql, [titre, plateforme, prix, quantites, genre, image], (err, result) => {
            if (err) {
                console.error('Erreur SQL:', err);
                return res.status(500).send('Erreur lors de l\'ajout du jeu');
            }

            console.log('Jeu ajouté avec succès, ID:', result.insertId);
            res.json({
                id: result.insertId,
                titre,
                plateforme,
                prix,
                quantites,
                genre, // Inclure genre dans la réponse
                image // Inclure l'image dans la réponse
            });
        });
    } catch (error) {
        console.error('Erreur dans la requête de l\'API:', error);
        res.status(500).send('Erreur lors de l\'ajout du jeu');
    }
});

// Route pour récupérer tous les jeux
app.get('/getGames', (req, res) => {
    const query = 'SELECT * FROM jeux';
    db.query(query, (err, results) => {
        if (err) {
            console.error(err);
            res.status(500).send('Erreur lors de la récupération des jeux');
        } else {
            res.json(results); // La description sera dans les résultats
        }
    });
});

// Ajouter un update 
app.post('/updateJeu', (req, res) => {
    const { id, titre, plateforme, prix, quantites, genre, image } = req.body; // Remplacement de description par genre

    // Log de debug
    console.log("Reçu :", req.body);

    if (!id || !titre || !plateforme || prix == null || quantites == null || genre == null || image == null) { // Vérifie si genre est présent
        return res.status(400).json({ error: 'Champs manquants ou invalides' });
    }

    const sql = 'UPDATE jeux SET titre = ?, plateforme = ?, prix = ?, quantites = ?, genre = ?, image = ? WHERE id = ?'; // Remplacer description par genre
    db.query(sql, [titre, plateforme, prix, quantites, genre, image, id], (err, result) => {
        if (err) {
            console.error('Erreur SQL:', err);
            return res.status(500).json({ error: 'Erreur lors de la mise à jour' });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Aucun jeu trouvé avec cet ID' });
        }

        console.log('Jeu mis à jour avec succès.');
        res.json({ message: 'Jeu mis à jour avec succès', id });
    });
});

//Supprimer un Jeu
app.post('/suppJeu', (req, res) => {
    const { id } = req.body;

    // Log de debug
    console.log("ID à supprimer :", id);

    if (!id) {
        return res.status(400).json({ error: 'ID manquant' });
    }

    // Requête SQL pour supprimer le jeu
    const sql = 'DELETE FROM jeux WHERE id = ?';
    db.query(sql, [id], (err, result) => {
        if (err) {
            console.error('Erreur SQL:', err);
            return res.status(500).json({ error: 'Erreur lors de la suppression' });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Aucun jeu trouvé avec cet ID' });
        }

        console.log('Jeu supprimé avec succès.');
        res.json({ message: 'Jeu supprimé avec succès', id });
    });
});

app.get('/jeux', (req, res) => {
    const sql = 'SELECT * FROM jeux;';
    db.query(sql, (err, results) => {
        if (err) {
            return res.status(500).send(err);
        }
        res.json(results);
    });
});


// Route pour rechercher des jeux
app.get('/jeux/recherche', (req, res) => {
    const { n, i, nsm } = req.query;

    // Construction de la requête SQL avec des conditions de recherche
    let sql = 'SELECT * FROM jeux WHERE 1=1';
    let params = [];

    // Ajouter les conditions de recherche selon les paramètres reçus
    if (n) {
        sql += ' AND titre LIKE ?';
        params.push(`%${n}%`); // Recherche partielle sur le nom (titre)
    }
    if (i) {
        sql += ' AND id LIKE ?';
        params.push(`%${i}%`); // Recherche partielle sur l'ID
    }
    if (nsm) {
        sql += ' AND plateforme LIKE ?';
        params.push(`%${nsm}%`); // Recherche partielle sur la plateforme
    }

    // Exécution de la requête SQL avec les paramètres de recherche
    db.query(sql, params, (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Erreur lors de la recherche');
        }
        // Retourner les résultats de la recherche
        res.json(results);
    });
});

// Récupérer les commandes en attente
app.get('/commandes', (req, res) => {
    const sql = 'SELECT * FROM commande WHERE etat = 1';
    db.query(sql, (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
});

// Mettre à jour le statut d'une commande
app.post('/commandes/:id/statut', (req, res) => {
    const { id } = req.params;
    const { etat } = req.body;

    if (![2, 3].includes(etat)) {
        return res.status(400).json({ error: 'État invalide' });
    }

    const sql = 'UPDATE commande SET etat = ? WHERE id = ?';
    db.query(sql, [etat, id], (err, result) => {
        if (err) {
            console.error('Erreur SQL:', err);
            return res.status(500).json({ error: 'Erreur lors de la mise à jour' });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Commande non trouvée' });
        }

        console.log(`Commande ${id} mise à jour en état ${etat}`);
        res.json({ message: `Commande ${id} mise à jour en état ${etat}` });
    });
});


// Démarrage du serveur
app.listen(port, () => {
    console.log(`Serveur API en écoute sur http://localhost:${port}`);
});