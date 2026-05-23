const Cryptocurrency = require('../models/Cryptocurrency');

// @route   GET /api/crypto
// @desc    Get all cryptocurrencies
// @access  Public
exports.getAllCrypto = async (req, res) => {
  try {
    const cryptos = await Cryptocurrency.find().sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: cryptos.length,
      data: cryptos
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   GET /api/crypto/gainers
// @desc    Get top gainers (highest percentage increase)
// @access  Public
exports.getGainers = async (req, res) => {
  try {
    const gainers = await Cryptocurrency.find()
      .sort({ change24h: -1 })
      .limit(10);

    res.status(200).json({
      success: true,
      count: gainers.length,
      data: gainers
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   GET /api/crypto/new
// @desc    Get newest listings
// @access  Public
exports.getNewListings = async (req, res) => {
  try {
    const newListings = await Cryptocurrency.find()
      .sort({ createdAt: -1 })
      .limit(10);

    res.status(200).json({
      success: true,
      count: newListings.length,
      data: newListings
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   POST /api/crypto
// @desc    Create new cryptocurrency
// @access  Private
exports.createCrypto = async (req, res) => {
  try {
    const { name, symbol, price, change24h, image } = req.body;

    // Validation
    if (!name || !symbol || !price || !image) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields (name, symbol, price, image)'
      });
    }

    // Check if symbol already exists
    const existingCrypto = await Cryptocurrency.findOne({ symbol: symbol.toUpperCase() });
    if (existingCrypto) {
      return res.status(400).json({
        success: false,
        message: 'Cryptocurrency with this symbol already exists'
      });
    }

    const crypto = await Cryptocurrency.create({
      name,
      symbol: symbol.toUpperCase(),
      price: parseFloat(price),
      change24h: parseFloat(change24h) || 0,
      image,
      createdBy: req.userId
    });

    res.status(201).json({
      success: true,
      message: 'Cryptocurrency created successfully',
      data: crypto
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @route   DELETE /api/crypto/:id
// @desc    Delete cryptocurrency (optional - for admin)
// @access  Private
exports.deleteCrypto = async (req, res) => {
  try {
    const crypto = await Cryptocurrency.findById(req.params.id);

    if (!crypto) {
      return res.status(404).json({
        success: false,
        message: 'Cryptocurrency not found'
      });
    }

    await Cryptocurrency.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: 'Cryptocurrency deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};