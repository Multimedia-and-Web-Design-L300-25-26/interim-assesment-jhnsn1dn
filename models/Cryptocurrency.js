const mongoose = require('mongoose');

const CryptoSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Please provide cryptocurrency name'],
      unique: true,
      trim: true
    },
    symbol: {
      type: String,
      required: [true, 'Please provide cryptocurrency symbol'],
      unique: true,
      uppercase: true,
      maxlength: 10
    },
    price: {
      type: Number,
      required: [true, 'Please provide price'],
      default: 0
    },
    change24h: {
      type: Number,
      required: [true, 'Please provide 24h change percentage'],
      default: 0
    },
    image: {
      type: String,
      required: [true, 'Please provide image URL']
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Cryptocurrency', CryptoSchema);