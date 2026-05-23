const express = require('express');
const router = express.Router();
const {
  getAllCrypto,
  getGainers,
  getNewListings,
  createCrypto,
  deleteCrypto
} = require('../controllers/cryptoController');
const authMiddleware = require('../middleware/auth');

// Public routes
router.get('/', getAllCrypto);
router.get('/gainers', getGainers);
router.get('/new', getNewListings);

// Private routes (require authentication)
router.post('/', authMiddleware, createCrypto);
router.delete('/:id', authMiddleware, deleteCrypto);

module.exports = router;