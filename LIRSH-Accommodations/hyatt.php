<?php
$hotelName = $_GET["hotel_name"];
$roomNumber = $_GET["room_number"];
$capacity = $_GET["capacity"];
$price = $_GET["price"];
$viewType = $_GET["view_type"];
?>

<!DOCTYPE html>
<html>

<head>
  <title>Room Booking Form</title>
  
  <style>
    body {
      background-color: lightsalmon;
      margin: 0;
      padding: 0;
      text-align: center;
      font-family: Arial, sans-serif;
    }

    .header {
      background-color: black;
      text-align: left;
    }

    .logo-button {
      top: 0;
      left: 0;
      padding: 0;
    }

    .header-button {
      margin: 0 30px;
    }

    .header-button, .logo-button img, .logo-button {
      background-color: transparent;
      color: white;
      border: none;
      height: 100px;
      vertical-align: middle;
      cursor: pointer;
    }

    .header-button:hover {
      background-color: #333;
    }
    
    .booking-form {
      width: 50%;
      margin: 20px auto;
      background-color: #f2f2f2;
      padding: 20px;
      border-radius: 10px;
      box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
      text-align: left;
    }
    
    .form-group {
      margin-bottom: 20px;
    }
    
    label {
      display: block;
      font-weight: bold;
      margin-bottom: 5px;
    }
    
    input[type="text"], input[type="date"], select {
      width: 100%;
      padding: 10px;
      border-radius: 5px;
      border: 1px solid #ccc;
      box-sizing: border-box;
      margin-top: 5px;
    }
    
    input[type="submit"] {
      background-color: lightblue;
      border: none;
      padding: 10px 20px;
      border-radius: 5px;
      cursor: pointer;
      font-size: 16px;
    }
  </style>
</head>

<body>
  <div class="header">
    <button class="logo-button" onclick="use_header('index')">
      <img src="logo.png">
    </button>
    <button class="header-button" onclick="use_header('Hyatt')">Hyatt Lodge</button>
    <button class="header-button" onclick="use_header('indigo')">Indigo Inns</button>
    <button class="header-button" onclick="use_header('regional')">Regional Resorts</button>
    <button class="header-button" onclick="use_header('serenity')">Serenity Spas</button>
    <button class="header-button" onclick="use_header('hyatt')">Hyatt Hotels</button>
  </div>
  
  <h1>Room Booking Details</h1>
  
  <div class="booking-form">
    <form>
      <div class="form-group">
        <label for="first_name">First Name:</label>
        <input type="text" id="first_name" name="first_name" required>
      </div>
      <div class="form-group">
        <label for="last_name">Last Name:</label>
        <input type="text" id="last_name" name="last_name" required>
      </div>
      <div class="form-group">
        <label for="id_type">ID Type Presented:</label>
        <select id="id_type" name="id_type" required>
          <option value="passport">Passport</option>
          <option value="driver_license">Driver's License</option>
          <option value="national_id">Health Card</option>
        </select>
      </div>
      <div class="form-group">
        <label for="payment_method">Payment Method:</label>
        <select id="payment_method" name="payment_method" required>
          <option value="credit_card">Credit Card</option>
          <option value="debit_card">Debit Card</option>
          <option value="cash">Cash</option>
        </select>
      </div>
      <div class="form-group">
        <label for="start_date">Start Date:</label>
        <input type="date" id="start_date" name="start_date" required>
      </div>
      <div class="form-group">
        <label for="end_date">End Date:</label>
        <input type="date" id="end_date" name="end_date" required>
      </div>
      <input type="hidden" name="hotel_name" value="<?php echo $hotelName; ?>">
      <input type="hidden" name="room_number" value="<?php echo $roomNumber; ?>">
      <input type="hidden" name="capacity" value="<?php echo $capacity; ?>">
      <input type="hidden" name="price" value="<?php echo $price; ?>">
      <input type="hidden" name="view_type" value="<?php echo $viewType; ?>">
      <input type="submit" value="Book Now" onclick = "add_info()">
    </form>
  </div>
  
  <script>
    function use_header(location) {
      window.location.href = location + ".php";
    }
    
    function add_info () {
        
    }
  </script>
</body>

</html>
