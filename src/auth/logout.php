<?php
session_start();
session_destroy();
header('Location: ../login.php?success=Logged out successfully');
exit();
?>
