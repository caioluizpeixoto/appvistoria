import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const vistoriaId = url.searchParams.get('id')

    if (!vistoriaId) {
      return new Response('ID da vistoria não fornecido.', { status: 400 })
    }

    // USANDO SERVICE ROLE PARA BYPASS RLS
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Pegar o PDF da pasta laudos-pdf
    const { data: pdfFiles } = await supabaseClient.storage.from('laudos-pdf').list(vistoriaId)
    let pdfUrl = ''
    if (pdfFiles && pdfFiles.length > 0) {
      const pdfName = pdfFiles[0].name
      const { data } = supabaseClient.storage.from('laudos-pdf').getPublicUrl(`${vistoriaId}/${pdfName}`)
      pdfUrl = data.publicUrl
    } else {
      return new Response('Laudo PDF não encontrado. O upload pode ainda estar em andamento.', { status: 404 })
    }

    // Buscar imagens na pasta da vistoria para a galeria
    const imageUrls: string[] = []
    const { data: rootFiles } = await supabaseClient.storage.from('vistorias').list(vistoriaId)
    
    if (rootFiles) {
      for (const item of rootFiles) {
        if (item.id) {
          const { data } = supabaseClient.storage.from('vistorias').getPublicUrl(`${vistoriaId}/${item.name}`)
          if (data.publicUrl && !data.publicUrl.endsWith('/.emptyFolderPlaceholder')) imageUrls.push(data.publicUrl)
        } else {
          // É pasta (ex: identificacao, avarias)
          const folderName = item.name
          const { data: subFiles } = await supabaseClient.storage.from('vistorias').list(`${vistoriaId}/${folderName}`)
          if (subFiles) {
            for (const subItem of subFiles) {
              if (subItem.id) {
                const { data } = supabaseClient.storage.from('vistorias').getPublicUrl(`${vistoriaId}/${folderName}/${subItem.name}`)
                if (data.publicUrl && !data.publicUrl.endsWith('/.emptyFolderPlaceholder')) imageUrls.push(data.publicUrl)
              }
            }
          }
        }
      }
    }

    // Usaremos PDF.js para renderizar o PDF diretamente no HTML, fazendo parecer que é o próprio site.
    // E adicionaremos um botão flutuante para abrir a galeria de fotos.
    const html = `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laudo Cautelar Inteligente</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js"></script>
    <style>
        body {
            margin: 0;
            padding: 0;
            background-color: #525659;
            display: flex;
            flex-direction: column;
            align-items: center;
            font-family: 'Inter', sans-serif;
            overflow-x: hidden;
        }

        #pdf-container {
            width: 100%;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 10px 0;
        }

        canvas {
            max-width: 100%;
            margin-bottom: 10px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            background-color: white;
        }

        /* Botão Flutuante da Galeria */
        .fab {
            position: fixed;
            bottom: 24px;
            right: 24px;
            background-color: #0288d1;
            color: white;
            border: none;
            border-radius: 50px;
            padding: 16px 24px;
            font-size: 16px;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(0,0,0,0.4);
            cursor: pointer;
            z-index: 100;
            display: flex;
            align-items: center;
            gap: 10px;
            transition: transform 0.2s;
        }

        .fab:hover {
            transform: scale(1.05);
            background-color: #0277bd;
        }

        .fab svg {
            width: 20px;
            height: 20px;
        }

        /* Botão Flutuante de Download PDF (Esquerda) */
        .fab-download {
            position: fixed;
            bottom: 24px;
            left: 24px;
            background-color: #333;
            color: white;
            border: none;
            border-radius: 50px;
            padding: 16px;
            font-size: 16px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.4);
            cursor: pointer;
            z-index: 100;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.2s;
            text-decoration: none;
        }

        .fab-download:hover {
            transform: scale(1.05);
            background-color: #444;
        }

        /* Galeria Overlay (Escondida por padrão) */
        #gallery-overlay {
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background-color: #0f1115;
            z-index: 200;
            display: none;
            flex-direction: column;
            overflow-y: auto;
            padding: 20px;
        }

        .gallery-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            color: white;
            margin-bottom: 20px;
        }

        .close-gallery {
            background: none;
            border: none;
            color: white;
            font-size: 30px;
            cursor: pointer;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
            gap: 16px;
        }

        .grid img {
            width: 100%;
            aspect-ratio: 1;
            object-fit: cover;
            border-radius: 8px;
            cursor: pointer;
            border: 1px solid #333;
        }

        /* Lightbox para ampliar imagem */
        #lightbox {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background-color: rgba(0,0,0,0.95);
            z-index: 300;
            justify-content: center;
            align-items: center;
        }

        #lightbox img {
            max-width: 95%;
            max-height: 90%;
            border-radius: 8px;
        }

        .close-lightbox {
            position: absolute;
            top: 20px;
            right: 20px;
            background: none;
            border: none;
            color: white;
            font-size: 40px;
            cursor: pointer;
        }
    </style>
</head>
<body>

    <div id="pdf-container">
        <!-- O PDF será renderizado aqui página por página -->
        <h3 style="color: white; margin-top: 50px;" id="loading-text">Carregando Laudo Oficial...</h3>
    </div>

    <!-- Botões -->
    <a href="${pdfUrl}" target="_blank" class="fab-download" title="Baixar PDF Original">
        <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" width="24" height="24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path>
        </svg>
    </a>

    <button class="fab" onclick="openGallery()">
        <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
        </svg>
        Ver Fotos
    </button>

    <!-- Galeria -->
    <div id="gallery-overlay">
        <div class="gallery-header">
            <h2>Fotos da Vistoria</h2>
            <button class="close-gallery" onclick="closeGallery()">&times;</button>
        </div>
        <div class="grid">
            ${imageUrls.map(url => `<img src="${url}" onclick="openLightbox('${url}')" loading="lazy">`).join('')}
            ${imageUrls.length === 0 ? '<p style="color: #aaa;">Nenhuma foto encontrada.</p>' : ''}
        </div>
    </div>

    <!-- Lightbox -->
    <div id="lightbox" onclick="closeLightbox()">
        <button class="close-lightbox" onclick="closeLightbox()">&times;</button>
        <img id="lightbox-img" src="">
    </div>

    <script>
        // Renderizar PDF usando PDF.js
        const url = "${pdfUrl}";
        const container = document.getElementById('pdf-container');
        const loadingText = document.getElementById('loading-text');

        if (url) {
            pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js';
            
            let pdfDoc = null;
            let scale = window.innerWidth < 800 ? (window.innerWidth / 600) : 1.5; // Ajuste automático de escala para caber no celular

            pdfjsLib.getDocument(url).promise.then(function(pdfDoc_) {
                pdfDoc = pdfDoc_;
                loadingText.style.display = 'none';

                // Renderizar todas as páginas
                for (let num = 1; num <= pdfDoc.numPages; num++) {
                    pdfDoc.getPage(num).then(function(page) {
                        const viewport = page.getViewport({scale: scale});
                        const canvas = document.createElement('canvas');
                        const ctx = canvas.getContext('2d');
                        canvas.height = viewport.height;
                        canvas.width = viewport.width;

                        const renderContext = {
                            canvasContext: ctx,
                            viewport: viewport
                        };

                        // Renderiza a página no canvas e adiciona ao container em ordem
                        page.render(renderContext).promise.then(function() {
                            // Para garantir ordem correta das páginas, podemos usar um placeholder
                        });
                        
                        // Uma técnica mais robusta para ordem é criar os canvas de antemão
                        canvas.id = 'page-' + num;
                        container.appendChild(canvas);
                    });
                }
            }).catch(function(error) {
                loadingText.innerText = 'Erro ao carregar o laudo: ' + error.message;
            });
        } else {
            loadingText.innerText = 'PDF não encontrado no servidor.';
        }

        // Funções da Galeria
        function openGallery() {
            document.getElementById('gallery-overlay').style.display = 'flex';
            document.body.style.overflow = 'hidden';
        }
        function closeGallery() {
            document.getElementById('gallery-overlay').style.display = 'none';
            document.body.style.overflow = 'auto';
        }

        // Funções do Lightbox
        function openLightbox(src) {
            document.getElementById('lightbox-img').src = src;
            document.getElementById('lightbox').style.display = 'flex';
        }
        function closeLightbox() {
            document.getElementById('lightbox').style.display = 'none';
        }
    </script>
</body>
</html>
    `

    return new Response(html, {
      status: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-cache, no-store, must-revalidate",
        "Pragma": "no-cache",
        "Expires": "0"
      },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    })
  }
})
