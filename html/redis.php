<?php
$redis = new Redis();
$redis->connect('db.redis',6379);
$redis->auth('');
$redis->select(0);
$ret = $redis->set('testkey', 'testvalue');
var_dump($ret);
$allKeys = $redis->keys('*');
print_r($allKeys);
?>
