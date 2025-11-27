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

        h1 {
            color: #333;
        }

        form {
            margin-top: 20px;
        }

        label {
            display: block;
            margin-bottom: 5px;
            color: #666;
        }

        input[type="text"] {
            width: 300px;
            padding: 8px; /* Un poco más de espacio */
            font-size: 14px;
            border: 1px solid #ccc;
            border-radius: 4px;
            margin-bottom: 10px;
        }

        /* --- AQUÍ ESTÁ EL ESTILO MODERNO PARA EL BOTÓN --- */
        .modern-btn {
            display: inline-block;
            padding: 12px 30px;
            font-size: 16px;
            font-weight: 600;
            background-color: #4CAF50; /* Color verde moderno */
            color: #fff !important; /* Texto blanco forzado */
            border: none;
            border-radius: 5px; /* Bordes redondeados modernos */
            cursor: pointer;
            text-align: center;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1); /* Sombra suave */
        }

        .modern-btn:hover {
            background-color: #45a049; /* Verde más oscuro al pasar mouse */
            transform: translateY(-2px); /* Efecto de elevación */
            box-shadow: 0 6px 8px rgba(0,0,0,0.15);
            color: #fff;
        }

        .modern-btn:active {
            transform: translateY(0); /* Efecto de click */
        }
        /* ------------------------------------------------ */

        .detail-box {
            display: flex;
            flex-direction: column;
            align-items: flex-start;
        }

        .detail-box form {
            align-self: flex-start;
        }

        .col-md-6 {
            display: flex;
            flex-direction: column;
            align-items: center;
        }
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
                        <p>
                            The check can take 5-10 seconds. After the check is complete, scroll down to view the results
                        </p>
                        <form onsubmit="event.preventDefault(); openWebsite();">
                            <label for="imei">IMEI:</label>
                            <input type="text" id="imei" name="imei"><br>
                            
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
        <h4 style="text-align:center; color:#4CAF50; margin-bottom:15px;">Results</h4>
        <iframe id="website-iframe" src="" style="width: 100%; height: 500px; border: 1px solid #ddd; border-radius: 5px;"></iframe>
    </div>

    <section class="container-fluid footer_section ">
        <div class="container">
            <p>
                developed by
                <a href="https://twitter.com/hackt1vator">@hackt1vator</a>
            </p>
        </div>
    </section>
    <script type="text/javascript" src="js/jquery-3.4.1.min.js"></script>
    <script type="text/javascript" src="js/bootstrap.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/OwlCarousel2/2.2.1/owl.carousel.min.js"></script>
    
    <script type="text/javascript">
        $(".owl-carousel").owlCarousel({
            loop: true,
            margin: 10,
            nav: true,
            navText: [],
            autoplay: true,
            autoplayHoverPause: true,
            responsive: {
                0: { items: 1 },
                420: { items: 2 },
                1000: { items: 5 }
            }
        });

        // ESTA ES TU LÓGICA ORIGINAL QUE SÍ FUNCIONABA
        function openWebsite() {
            var imei = document.getElementById("imei").value;
            var imei2 = document.getElementById("imei2").value;
            var sn = document.getElementById("sn").value;
            var url = "https://yosoyhendrix.com/imei/check.php";
            var params = [];

            if (imei.trim() !== "") {
                params.push("imei=" + imei);
            }
            if (imei2.trim() !== "") {
                params.push("imei2=" + imei2);
            }
            if (sn.trim() !== "") {
                params.push("sn=" + sn);
            }

            if (params.length > 0) {
                // Tu lógica de concatenación original
                url += "?" + params.join("&");
                
                var websiteIframe = document.getElementById("website-iframe");
                websiteIframe.src = url;
                document.querySelector(".website-content").style.display = "block";
                
                // Agregué este pequeño scroll automático para mejorar la UX sin tocar la lógica
                // Si no te gusta, puedes borrar la línea de abajo.
                document.querySelector(".website-content").scrollIntoView({behavior: "smooth"});
            } else {
                alert("Please fill in the fields.");
            }
        }
    </script>
</body>
</html>
