<?php

$mysqli = new mysqli('127.0.0.1', getenv('OPENCART_DB_USER') ?: 'opencart', getenv('OPENCART_DB_PASSWORD') ?: 'opencart', getenv('OPENCART_DB_NAME') ?: 'opencart', 3306);
if ($mysqli->connect_error) {
    fwrite(STDERR, "database connection failed\n");
    exit(1);
}

$prefix = 'oc_';
$baseUrl = rtrim(getenv('JUNOPAY_BASE_URL') ?: '', '/');
$apiKey = getenv('JUNOPAY_MERCHANT_API_KEY') ?: '';
$webhookSecret = getenv('JUNOPAY_WEBHOOK_SECRET') ?: '';

function q(mysqli $db, string $sql): void {
    if (!$db->query($sql)) {
        fwrite(STDERR, $db->error . "\n");
        exit(1);
    }
}

function setting(mysqli $db, string $key, string $value, bool $serialized = false): void {
    $code = 'payment_junopay';
    $keyEsc = $db->real_escape_string($key);
    $valueEsc = $db->real_escape_string($value);
    $serializedInt = $serialized ? 1 : 0;
    q($db, "DELETE FROM oc_setting WHERE store_id = 0 AND `code` = '{$code}' AND `key` = '{$keyEsc}'");
    q($db, "INSERT INTO oc_setting SET store_id = 0, `code` = '{$code}', `key` = '{$keyEsc}', `value` = '{$valueEsc}', serialized = {$serializedInt}");
}

q($mysqli, "INSERT IGNORE INTO oc_extension SET type = 'payment', code = 'junopay'");
setting($mysqli, 'payment_junopay_status', '1');
setting($mysqli, 'payment_junopay_sort_order', '1');
setting($mysqli, 'payment_junopay_order_status_id', '1');
setting($mysqli, 'payment_junopay_geo_zone_id', '0');
setting($mysqli, 'payment_junopay_title', 'JunoPay');
setting($mysqli, 'payment_junopay_api_base_url', $baseUrl);
setting($mysqli, 'payment_junopay_merchant_api_key', $apiKey);
setting($mysqli, 'payment_junopay_webhook_secret', $webhookSecret);
setting($mysqli, 'payment_junopay_zatoshis_per_currency_unit', '100000000');

q($mysqli, "DELETE FROM oc_setting WHERE store_id = 0 AND `code` = 'config' AND `key` IN ('config_currency', 'config_name', 'config_meta_title')");
q($mysqli, "INSERT INTO oc_setting SET store_id = 0, `code` = 'config', `key` = 'config_currency', `value` = 'JUN', serialized = 0");
q($mysqli, "INSERT INTO oc_setting SET store_id = 0, `code` = 'config', `key` = 'config_name', `value` = 'JunoPay OpenCart Demo', serialized = 0");
q($mysqli, "INSERT INTO oc_setting SET store_id = 0, `code` = 'config', `key` = 'config_meta_title', `value` = 'JunoPay OpenCart Demo', serialized = 0");
q($mysqli, "INSERT IGNORE INTO oc_currency SET title = 'JUNO', code = 'JUN', symbol_left = 'JUNO ', symbol_right = '', decimal_place = '8', value = '1.00000000', status = 1, date_modified = NOW()");

q($mysqli, "SET FOREIGN_KEY_CHECKS = 0");
foreach (array(
    'oc_product',
    'oc_product_attribute',
    'oc_product_description',
    'oc_product_discount',
    'oc_product_filter',
    'oc_product_image',
    'oc_product_option',
    'oc_product_option_value',
    'oc_product_recurring',
    'oc_product_related',
    'oc_product_reward',
    'oc_product_special',
    'oc_product_to_category',
    'oc_product_to_download',
    'oc_product_to_layout',
    'oc_product_to_store',
) as $table) {
    q($mysqli, "TRUNCATE TABLE {$table}");
}
q($mysqli, "SET FOREIGN_KEY_CHECKS = 1");

q($mysqli, "INSERT INTO oc_product SET model = 'AIR-1', sku = '', upc = '', ean = '', jan = '', isbn = '', mpn = '', location = '', quantity = 999, stock_status_id = 7, image = '', manufacturer_id = 0, shipping = 0, price = '1.00000000', points = 0, tax_class_id = 0, date_available = CURDATE(), weight = 0, weight_class_id = 1, length = 0, width = 0, height = 0, length_class_id = 1, subtract = 0, minimum = 1, sort_order = 1, status = 1, viewed = 0, date_added = NOW(), date_modified = NOW()");
$productId = $mysqli->insert_id;
q($mysqli, "INSERT INTO oc_product_description SET product_id = {$productId}, language_id = 1, name = '1 gallon of air', description = 'A demo product for the JunoPay OpenCart gateway.', tag = '', meta_title = '1 gallon of air', meta_description = '', meta_keyword = ''");
q($mysqli, "INSERT INTO oc_product_to_store SET product_id = {$productId}, store_id = 0");
q($mysqli, "INSERT INTO oc_product_to_category SET product_id = {$productId}, category_id = 20");

$mysqli->close();
