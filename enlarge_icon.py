import sys
import os

try:
    from PIL import Image
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

def enlarge_icon(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    
    # Encontra o bounding box da parte no-transparente
    bbox = img.getbbox()
    if bbox:
        cropped = img.crop(bbox)
        
        max_dim = max(cropped.width, cropped.height)
        # Adiciona apenas um pouquinho de padding (5% a 10%) para a imagem parecer maior
        # Se antes tinha 30% de padding, agora ter bem menos.
        new_size = int(max_dim * 1.1)
        
        new_img = Image.new("RGBA", (new_size, new_size), (255, 255, 255, 0))
        
        offset_x = (new_size - cropped.width) // 2
        offset_y = (new_size - cropped.height) // 2
        
        new_img.paste(cropped, (offset_x, offset_y))
        
        new_img = new_img.resize(img.size, Image.Resampling.LANCZOS)
        new_img.save(output_path)
        print(f"Sucesso: Imagem recortada e ampliada. Salvo em {output_path}")
    else:
        print("Imagem est vazia (toda transparente).")

if __name__ == "__main__":
    base_dir = r"c:\Users\Caio\Desktop\app_vistoria\assets\images"
    input_img = os.path.join(base_dir, "app_icon.png")
    backup_img = os.path.join(base_dir, "app_icon_backup.png")
    
    if not os.path.exists(backup_img):
        # Cria backup se no existir
        with open(input_img, 'rb') as f_in, open(backup_img, 'wb') as f_out:
            f_out.write(f_in.read())
            
    # Sobrescreve a imagem original
    enlarge_icon(backup_img, input_img)
