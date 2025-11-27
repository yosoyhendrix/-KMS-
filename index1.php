<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="keywords" content="">
    <meta name="description" content="">
    <meta name="author" content="">
    <title>Hackt1vator</title>
    <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/OwlCarousel2/2.1.3/assets/owl.carousel.min.css">
    <link rel="stylesheet" type="text/css" href="css/bootstrap.css">
    <link href="https://fonts.googleapis.com/css?family=Open+Sans:400,700|Poppins:400,700&amp;display=swap" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
    <link href="css/responsive.css" rel="stylesheet">

    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }

        h1 { color: #333; }
        form { margin-top: 20px; }
        label { display: block; margin-bottom: 5px; color: #666; }

        input[type="text"] {
            width: 300px;
            padding: 8px;
            font-size: 14px;
            border: 1px solid #ccc;
            border-radius: 4px;
            margin-bottom: 10px;
        }

        /* --- ESTILO MODERNO PARA EL BOTÓN --- */
        .modern-btn {
            display: inline-block;
            padding: 12px 30px;
            font-size: 16px;
            font-weight: 600;
            background-color: #4CAF50;
            color: #fff !important;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-align: center;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        .modern-btn:hover {
            background-color: #45a049;
            transform: translateY(-2px);
            box-shadow: 0 6px 8px rgba(0,0,0,0.15);
            color: #fff;
        }

        .modern-btn:active { transform: translateY(0); }

        /* Estilo para el resultado del modelo detectado */
        #local-result {
            margin-bottom: 15px;
            padding: 15px;
            background-color: #f8f9fa;
            border-left: 5px solid #4CAF50;
            border-radius: 4px;
            display: none; /* Oculto por defecto */
        }
        #model-name {
            font-weight: bold;
            color: #333;
            font-size: 1.2rem;
        }

        .detail-box { display: flex; flex-direction: column; align-items: flex-start; }
        .detail-box form { align-self: flex-start; }
        .col-md-6 { display: flex; flex-direction: column; align-items: center; }
    </style>

    <style type="text/css">
        * { user-select: auto !important; -webkit-user-select: auto !important; }
    </style>
    <input type="hidden" id="inject_idm_text_selection">
</head>

<body class="sub_page">
    <div class="hero_area">
        <header class="header_section">
            <div class="container-fluid">
                <nav class="navbar navbar-expand-lg custom_nav-container">
                    <a class="navbar-brand" href="https://hackt1vator.com/default.php">
                        <img src="images/logo.png" alt="">
                    </a>
                    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                        <span class="navbar-toggler-icon"></span>
                    </button>
                </nav>
            </div>
        </header>
    </div>

    <section class="about_section layout_padding">
        <div class="container">
            <div class="row">
                <div class="col-md-6">
                    <div class="detail-box">
                        <h1>Free Check</h1>
                        <p>The check can take 5-10 seconds. After the check is complete, scroll down to view the results</p>
                        <form onsubmit="event.preventDefault(); openWebsite();">
                            <label for="imei">IMEI:</label>
                            <input type="text" id="imei" name="imei" placeholder="35..."><br>
                            
                            <label for="imei2">IMEI2 (Only for iPhone XS or higher):</label>
                            <input type="text" id="imei2" name="imei2"><br>
                            
                            <label for="sn">SN:</label>
                            <input type="text" id="sn" name="sn"><br><br>

                            <button type="button" class="modern-btn" onclick="openWebsite()">Check Now</button>
                        </form>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="img-box">
                        <img src="iphone.png" alt="" style="width: 300px;">
                    </div>
                </div>
            </div>
        </div>
    </section>
    
    <div class="website-content" style="display: none; padding: 20px;">
        <div class="container">
            
            <div id="local-result">
                <span>Detected Device based on TAC: </span>
                <span id="model-name">Calculating...</span>
            </div>

            <h4 style="text-align:center; color:#4CAF50; margin-bottom:15px;">Server Results</h4>
            <iframe id="website-iframe" src="" style="width: 100%; height: 500px; border: 1px solid #ddd; border-radius: 5px;"></iframe>
        </div>
    </div>

    <section class="container-fluid footer_section ">
        <div class="container">
            <p>developed by <a href="https://twitter.com/hackt1vator">@hackt1vator</a></p>
        </div>
    </section>

    <script type="text/javascript" src="js/jquery-3.4.1.min.js"></script>
    <script type="text/javascript" src="js/bootstrap.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/OwlCarousel2/2.2.1/owl.carousel.min.js"></script>
    
    <script type="text/javascript">
        $(".owl-carousel").owlCarousel({
            loop: true, margin: 10, nav: true, navText: [], autoplay: true,
            autoplayHoverPause: true, responsive: { 0: { items: 1 }, 420: { items: 2 }, 1000: { items: 5 } }
        });

        // --- BASE DE DATOS DE TAC (Primeros 8 dígitos del IMEI) ---
        // Esto ayuda a identificar el modelo aunque el servidor falle.
        function getModelFromTAC(imei) {
            if (!imei || imei.length < 8) return "Unknown (Check IMEI)";
            
            var tac = imei.substring(0, 8);
            
            // Lista simplificada de TACs comunes de iPhone
            // Puedes añadir más TACs aquí si los encuentras
            var tacDb = {
                "35728509": "iPhone 6s", "35325807": "iPhone 6s",
                "35914907": "iPhone 7", "35540308": "iPhone 7 Plus",
                "35674008": "iPhone 8", "35298809": "iPhone 8 Plus",
                "35673408": "iPhone X", "35487909": "iPhone X",
                "35740009": "iPhone XR", "35306310": "iPhone XS",
                "35655709": "iPhone XS Max", "35293211": "iPhone 11",
                "35308611": "iPhone 11 Pro", "35306211": "iPhone 11 Pro Max",
                "35304711": "iPhone SE (2020)",
                "35183812": "iPhone 12", "35189712": "iPhone 12 Pro",
                "35294512": "iPhone 12 Pro Max", "35301812": "iPhone 12 Mini",
                "35027521": "iPhone 13", "35467439": "iPhone 13 Pro",
                "35345789": "iPhone 13 Pro Max",
                "35058765": "iPhone 14", "35060449": "iPhone 14 Pro",
                "35061699": "iPhone 14 Pro Max"
            };

            // Búsqueda exacta
            if (tacDb[tac]) return tacDb[tac];

            // Si no encuentra exacto, intenta lógica aproximada (menos precisa)
            if (tac.startsWith("35")) return "Apple Device (Generic)";
            
            return "Unknown / Not in Local DB";
        }

        function openWebsite() {
            var imei = document.getElementById("imei").value.trim();
            var imei2 = document.getElementById("imei2").value.trim();
            var sn = document.getElementById("sn").value.trim();
            var url = "https://yosoyhendrix.com/imei/check.php";
            var params = [];

            if (imei !== "") params.push("imei=" + imei);
            if (imei2 !== "") params.push("imei2=" + imei2);
            if (sn !== "") params.push("sn=" + sn);

            if (params.length > 0) {
                url += "?" + params.join("&");
                
                // 1. Mostrar Iframe
                var websiteIframe = document.getElementById("website-iframe");
                websiteIframe.src = url;
                document.querySelector(".website-content").style.display = "block";

                // 2. Lógica local para detectar modelo
                var detectedModel = "Unknown";
                if(imei.length >= 8) {
                    detectedModel = getModelFromTAC(imei);
                } else if (sn.length > 0) {
                    detectedModel = "Check below (SN provided)";
                }

                // 3. Mostrar resultado local
                document.getElementById("model-name").innerText = detectedModel;
                document.getElementById("local-result").style.display = "block";

                // 4. Scroll
                document.querySelector(".website-content").scrollIntoView({behavior: "smooth"});
            } else {
                alert("Please fill in the IMEI or SN fields.");
            }
        }
    </script>
</body>
</html>
