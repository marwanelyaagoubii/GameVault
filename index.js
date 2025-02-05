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
    host: '10.50.0.6', // Remplacez par l'IP de votre serveur MySQL
    user: 'marwan', // Nom d'utilisateur de la base de données
    password: 'Marwan84700.', // Mot de passe de la base de données
    database: 'administrateur' // Nom de la base de données
});

// Connexion à MySQL
db.connect((err) => {
    if (err) {
        console.error('Erreur de connexion à MySQL:', err);
        return;
    }
    console.log('Connecté à la base de données MySQL');
    console.log(`Connecté vous à PHPMyAdmin http://10.50.0.6/phpmyadmin `);
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

// --------------------------------------
// Routes de gestion des jeux vidéo
// --------------------------------------

// Ajouter un jeu
app.post('/ajouterJeu', async(req, res) => {
    const { titre, plateforme } = req.body;

    try {
        console.log('Données reçues : Titre -', titre, ', Plateforme -', plateforme);

        const sql = 'INSERT INTO jeux (titre, plateforme) VALUES (?, ?)';
        db.query(sql, [titre, plateforme], (err, result) => {
            if (err) {
                console.error('Erreur SQL:', err);
                return res.status(500).send('Erreur lors de l\'ajout du jeu');
            }
            console.log('Jeu ajouté avec succès, ID:', result.insertId);
            res.json({
                id: result.insertId,
                titre,
                plateforme
            });
        });
    } catch (error) {
        console.error('Erreur dans la requête de l\'API:', error);
        res.status(500).send('Erreur lors de l\'ajout du jeu');
    }
});


// Démarrage du serveur
app.listen(port, () => {
    console.log(`Serveur API en écoute sur http://localhost:${port}`);
});