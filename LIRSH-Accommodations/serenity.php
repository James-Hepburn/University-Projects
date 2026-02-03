<!DOCTYPE html>
<html>

<head>
  <title>Serenity Spas</title>
  
  <style>
    body {
      background-color: lightsalmon;
      margin: 0;
      padding: 0;
      text-align: center;
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
    
    .filter-box {
      background-color: #fff;
      width: 175px;
      height: 675px;
      padding: 10px;
      border-radius: 5px;
      box-shadow: 0 0 10px rgba (0, 0, 0, 0.2);
      position: absolute;
      top: 65%;
      left: 8%;
      transform: translate(-50%, -50%);
      text-align: left;
    }

    .filter-label {
      font-weight: bolder;
      font-size: large;
      text-align: center;
    }

    .checkbox-item, .date-item {
      display: flex;
      align-items: center;
      margin-bottom: 5px;
    }

    label {
      font-weight: bold;
      margin-top: 10px; 
      display: block; 
    }
    
    .room-list {
        display: grid;
        grid-template-columns: repeat(5, 1fr); 
        gap: 15px;
        justify-content: center; 
        margin-left: 250px; 
    }
    
    .room-item {
        text-align: left; 
        display: inline-block;
        margin-top: 50px;
        background-color: white;
        padding: 5px;
        border-radius: 5px;
        width: 175px;
    }
    
    .book-button {
        display: block; 
        margin: 0 auto;
        background-color: lightblue;
        border: none;
        padding: 5px;
        margin-top: 5px;
        border-radius: 5px;
        cursor: pointer;
    }
  </style>
</head>

<body>
  <div class="header">
    <button class="logo-button" onclick="use_header('index')">
      <img src="logo.png">
    </button>
    <button class="header-button" onclick="use_header('Serenity')">Serenity Lodge</button>
    <button class="header-button" onclick="use_header('indigo')">Indigo Inns</button>
    <button class="header-button" onclick="use_header('regional')">Regional Resorts</button>
    <button class="header-button" onclick="use_header('serenity')">Serenity Spas</button>
    <button class="header-button" onclick="use_header('hyatt')">Hyatt Hotels</button>
  </div>
  
   <div class="filter-box">
        <p class="filter-label">Room Filter</p>
        <div class="filter-options">
          <label>Start Date:</label>
          <div class="date-item"><input type="date" id = "start-date" onchange = "apply_filter()"></div>
    
          <label>End Date:</label>
          <div class="date-item"><input type="date" id = "end-date" onchange = "apply_filter()"></div>
          
          <label>View Type:</label>
          <div class="checkbox-item"><input type="checkbox" id = "mountain-view" onchange = "apply_filter()">Mountain</div>
          <div class="checkbox-item"><input type="checkbox" id = "sea-view" onchange = "apply_filter()">Sea</div>
    
          <label>Location:</label>
          <div class="checkbox-item"><input type="checkbox" id = "tokyo" onchange = "apply_filter()">Tokyo</div>
          <div class="checkbox-item"><input type="checkbox" id = "sydney" onchange = "apply_filter()">Sydney</div>
          <div class="checkbox-item"><input type="checkbox" id = "paris" onchange = "apply_filter()">Paris</div>
          <div class="checkbox-item"><input type="checkbox" id = "ny" onchange = "apply_filter()">New York</div>
          <div class="checkbox-item"><input type="checkbox" id = "london" onchange = "apply_filter()">London</div>
          <div class="checkbox-item"><input type="checkbox" id = "dubai" onchange = "apply_filter()">Dubai</div>
          <div class="checkbox-item"><input type="checkbox" id = "shanghai" onchange = "apply_filter()">Shanghai</div>
          <div class="checkbox-item"><input type="checkbox" id = "rome" onchange = "apply_filter()">Rome</div>
    
          <label>Star Rating:</label>
          <div class="checkbox-item"><input type="checkbox" id = "one-star" onchange = "apply_filter()">1</div>
          <div class="checkbox-item"><input type="checkbox" id = "two-star" onchange = "apply_filter()">2</div>
          <div class="checkbox-item"><input type="checkbox" id = "three-star" onchange = "apply_filter()">3</div>
          <div class="checkbox-item"><input type="checkbox" id = "four-star" onchange = "apply_filter()">4</div>
          <div class="checkbox-item"><input type="checkbox" id = "five-star" onchange = "apply_filter()">5</div>
    
          <label>Price:</label>
          <div class="checkbox-item"><input type="checkbox" id = "low" onchange = "apply_filter()">$</div>
          <div class="checkbox-item"><input type="checkbox" id = "mid" onchange = "apply_filter()">$$</div>
          <div class="checkbox-item"><input type="checkbox" id = "high" onchange = "apply_filter()">$$$</div>
        </div>
      </div>
  
    <div class="room-list">
        <?php
        $conn = new mysqli("localhost", "u547136864_jameshepburn", "James@300191654", "u547136864_ehotels");
        
        $locations = array(
            "Tokyo" => "Serenity tokyo",
            "Sydney" => "Serenity sydney",
            "Paris" => "Serenity paris",
            "New York" => "Serenity new york",
            "London" => "Serenity london",
            "Dubai" => "Serenity dubai",
            "Shanghai" => "Serenity shanghai",
            "Rome" => "Serenity rome"
        );
        
        foreach ($locations as $location => $hotel_name) {
            $query = "SELECT r.*, h.number_of_stars AS category
                      FROM Room r 
                      INNER JOIN Hotel h ON r.hotel_name = h.hotel_name 
                      WHERE r.hotel_name = '$hotel_name'";
            $result = $conn->query($query);
            while ($row = $result->fetch_assoc()) {
                echo "<div class='room-item' data-view-type='" . $row["view_type"] . "' data-star-rating='" . $row["category"] . "' data-hotel-name='" . $row["hotel_name"] . "' data-cost='" . $row["price"] . "'>";
                echo "<strong>" . $row["hotel_name"] . " - # " . $row["room_number"] . "</strong>" . "<br>";
                echo "Capacity: " . $row["capacity"] . "<br>";
                echo "Extendable: " . ($row["extendable"] ? "Yes" : "No") . "<br>";
                echo "Price: $" . $row["price"] . " per night<br>";
                echo "View Type: " . $row["view_type"] . "<br>";
                echo "<button class='book-button' onclick=\"ToBooking('bookroom.php', '{$row["hotel_name"]}', '{$row["room_number"]}', '{$row["capacity"]}', '{$row["price"]}', '{$row["view_type"]}')\">Book Room</button>";
                echo "</div>";
            }
        }
        
        $conn->close();
        ?>
    </div>
  
  <script>
    function use_header (location) {
      window.location.href = location + ".php";
    }
    
    function apply_filter() {
        var mountain_box = document.getElementById ("mountain-view").checked;
        var sea_box = document.getElementById ("sea-view").checked;
        var one_box = document.getElementById ("one-star").checked;
        var two_box = document.getElementById ("two-star").checked;
        var three_box = document.getElementById ("three-star").checked;
        var four_box = document.getElementById ("four-star").checked;
        var five_box = document.getElementById ("five-star").checked;
        var tokyo_box = document.getElementById ("tokyo").checked;
        var sydney_box = document.getElementById ("sydney").checked;
        var paris_box = document.getElementById ("paris").checked;
        var ny_box = document.getElementById ("ny").checked;
        var london_box = document.getElementById ("london").checked;
        var dubai_box = document.getElementById ("dubai").checked;
        var shanghai_box = document.getElementById ("shanghai").checked;
        var rome_box = document.getElementById ("rome").checked;
        var low_box = document.getElementById ("low").checked;
        var mid_box = document.getElementById ("mid").checked;
        var high_box = document.getElementById ("high").checked;
        var start_date = document.getElementById("start-date").value;
        var end_date = document.getElementById("end-date").value;

        var roomItems = document.querySelectorAll (".room-item");
    
        roomItems.forEach (function(roomItem) {
          var viewType = roomItem.dataset.viewType;
          var starRating = parseInt(roomItem.dataset.starRating);
          var hotel = roomItem.dataset.hotelName;
          var price = parseFloat(roomItem.dataset.cost);
          
          var viewMatch = (mountain_box && viewType == "Mountain") || (sea_box && viewType == "Sea") || (!mountain_box && !sea_box);
          var starMatch = (one_box && starRating == 1) || (two_box && starRating == 2) || (three_box && starRating == 3) || (four_box && starRating == 4) || (five_box && starRating == 5) || (!one_box && !two_box && !three_box && !four_box && !five_box);
          var locationMatch = (tokyo_box && hotel == "Serenity Tokyo") || (sydney_box && hotel == "Serenity Sydney") || (paris_box && hotel == "Serenity Paris") || (ny_box && hotel == "Serenity New York") || (london_box && hotel == "Serenity London") || (dubai_box && hotel == "Serenity Dubai") || (shanghai_box && hotel == "Serenity Shanghai") || (rome_box && hotel == "Serenity Rome") || (!tokyo_box && !sydney_box && !paris_box && !ny_box && !london_box && !dubai_box && !shanghai_box && !rome_box);
          var priceMatch = (low_box && price >= 0 && price <= 100) || (mid_box && price >= 100 && price <= 200) || (high_box && price >= 200 && price <= 300) || (!low_box && !mid_box && !high_box);
      
          if (viewMatch && starMatch && locationMatch && priceMatch) {
            roomItem.style.display = "block";
          } else {
            roomItem.style.display = "none";
          }
        });
      }
      
      function ToBooking (destination, hotelName, roomNumber, capacity, price, viewType) {
        var url = destination + "?hotel_name=" + hotelName + "&room_number=" + roomNumber + "&capacity=" + capacity + "&price=" + price + "&view_type=" + viewType;
        window.location.href = url;
      }
  </script>
</body>

</html>
