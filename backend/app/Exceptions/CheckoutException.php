<?php

namespace App\Exceptions;

use RuntimeException;

/**
 * Thrown when a checkout cannot be completed — an item sold out, a product was
 * archived, or a variant disappeared. The message is safe to show a customer,
 * and the controller turns it into a 422 rather than a 500.
 */
class CheckoutException extends RuntimeException
{
}
