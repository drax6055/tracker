const express = require('express');
const UserController = require('../controllers/user.controller');
const { protect } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const { updateProfileSchema } = require('../validations/auth.validation');

const router = express.Router();

router.use(protect);

router.get('/me', UserController.getMe);
router.patch('/me', validate(updateProfileSchema), UserController.updateMe);
router.delete('/me', UserController.deleteMe);

module.exports = router;
