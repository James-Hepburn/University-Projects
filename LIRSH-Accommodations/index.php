<!DOCTYPE html>
<html>

<head>
  <title>LIRSH Accommodations</title>
  
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

    .empty-logo {
      width: 600px;
      height: 500px;
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
    }
  </style>
</head>

<body>
  <div class = "header">
    <button class = "logo-button" onclick = "use_header ('index')">
      <img src = "logo.png">
    </button>
    <button class = "header-button" onclick = "use_header ('lakewood')">Lakewood Lodge</button>
    <button class = "header-button" onclick = "use_header ('indigo')">Indigo Inns</button>
    <button class = "header-button" onclick = "use_header ('regional')">Regional Resorts</button>
    <button class = "header-button" onclick = "use_header ('serenity')">Serenity Spas</button>
    <button class = "header-button" onclick = "use_header ('hyatt')">Hyatt Hotels</button>
  </div>

  <img class = "empty-logo" src = "empty-logo.png">
  
  <script>
    function use_header (location) {
      window.location.href = location + ".php";
    }
  </script>
</body>

</html>
