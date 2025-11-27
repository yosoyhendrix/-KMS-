<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="keywords" content="">
    <meta name="description" content="">
    <meta name="author" content="">
    <title>Free Check</title>
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
                    <a class="navbar-brand" href="https://yosoyhendrix.com/imei">
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
            <p>developed by <a href="https://instagram.com/yosoyhendrix">@yosoyhendrix</a></p>
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
    
    // Lista AMPLIADA de TACs (Type Allocation Code) comunes de iPhone
    var tacDb = {
        // --- iPhone 6 / 6 Plus / SE (1ra Gen) ---
        "35201107": "iPhone 6",
        "35201207": "iPhone 6 Plus",
        "35925006": "iPhone 6s",
        "35325807": "iPhone 6s", // Ya en lista
        "35728509": "iPhone 6s", // Ya en lista
        "35325907": "iPhone 6s Plus",
        "35728609": "iPhone 6s Plus",
        "35661109": "iPhone SE (1ra Gen)",

        // --- iPhone 7 / 8 / X ---
        "35914907": "iPhone 7", // Ya en lista
        "35538308": "iPhone 7",
        "35540308": "iPhone 7 Plus", // Ya en lista
        "35535408": "iPhone 7 Plus", // Ya en lista
        "35674008": "iPhone 8", // Ya en lista
        "35298809": "iPhone 8 Plus", // Ya en lista
        "35673408": "iPhone X", // Ya en lista
        "35487909": "iPhone X", // Ya en lista
        
        // --- iPhone XR / XS / 11 Series / SE (2020) ---
        "35740009": "iPhone XR", // Ya en lista
        "35306310": "iPhone XS", // Ya en lista
        "35655709": "iPhone XS Max", // Ya en lista
        "35293211": "iPhone 11", // Ya en lista
        "35397510": "iPhone 11", // Ya en lista
        "35308611": "iPhone 11 Pro", // Ya en lista
        "35306211": "iPhone 11 Pro Max", // Ya en lista
        "35304711": "iPhone SE (2020)", // Ya en lista
        
        // --- iPhone 12 Series ---
        "35183812": "iPhone 12", // Ya en lista
        "35442512": "iPhone 12",
        "35282212": "iPhone 12",
        "35189712": "iPhone 12 Pro", // Ya en lista
        "35451712": "iPhone 12 Pro",
        "35674091": "iPhone 12 Pro",
        "35400984": "iPhone 12 Pro",
        "35294512": "iPhone 12 Pro Max", // Ya en lista
        "35451812": "iPhone 12 Pro Max",
        "35301812": "iPhone 12 Mini", // Ya en lista
        "35282412": "iPhone 12 Mini",
        
        // --- iPhone 13 Series ---
        "35027521": "iPhone 13", // Ya en lista
        "35467339": "iPhone 13",
        "35654314": "iPhone 13",
        "35027621": "iPhone 13 Mini",
        "35289114": "iPhone 13 Mini",
        "35467439": "iPhone 13 Pro", // Ya en lista
        "35791221": "iPhone 13 Pro",
        "35654214": "iPhone 13 Pro",
        "35345789": "iPhone 13 Pro Max", // Ya en lista
        "35289014": "iPhone 13 Pro Max",
        
        // --- iPhone 14 Series ---
        "35058765": "iPhone 14", // Ya en lista
        "35443914": "iPhone 14",
        "35898022": "iPhone 14",
        "35058865": "iPhone 14 Plus",
        "35252914": "iPhone 14 Plus",
        "35898122": "iPhone 14 Plus",
        "35060449": "iPhone 14 Pro", // Ya en lista
        "35252814": "iPhone 14 Pro",
        "35879073": "iPhone 14 Pro",
        "35898222": "iPhone 14 Pro",
        "35061699": "iPhone 14 Pro Max", // Ya en lista
        "35898322": "iPhone 14 Pro Max",
        "35134435": "iPhone 14 Pro Max",

        // --- iPhone 15 Series / SE (2022) ---
        "35860017": "iPhone SE (2022)", 
        "35860117": "iPhone SE (2022)",
        "35798999": "iPhone 15",
        "35606615": "iPhone 15",
        "35400015": "iPhone 15",
        "35798899": "iPhone 15 Plus",
        "35400115": "iPhone 15 Plus",
        "35799099": "iPhone 15 Pro",
        "35362930": "iPhone 15 Pro",
        "35400215": "iPhone 15 Pro",
        "35799199": "iPhone 15 Pro Max",
        "35400315": "iPhone 15 Pro Max",
        "35108612": "iPhone 16",
        "35629560": "iPhone 16 Pro",
        "35355824": "iPhone 16 Pro Max",
    };

    // Búsqueda exacta
    if (tacDb[tac]) return tacDb[tac];

    // Si no encuentra exacto, intenta lógica aproximada (menos precisa)
    // El prefijo '35' es común y casi universal para dispositivos Apple GSM/LTE.
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
