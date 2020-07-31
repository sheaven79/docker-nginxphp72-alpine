<?php
$redis = new Redis();
$redis->connect('db.redis',6379);
$redis->auth('password');
$info = $redis->info();
print_r(json_encode($info));
?>
