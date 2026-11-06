from rembg import remove
from PIL import Image

def remove_background(input_path, output_path):
    print(f"Processing {input_path}...")
    try:
        input_image = Image.open(input_path)
        output_image = remove(input_image)
        output_image.save(output_path, "PNG")
        print(f"Saved to {output_path}")
    except Exception as e:
        print(f"Error processing {input_path}: {e}")

if __name__ == "__main__":
    remove_background(r"c:\shop\customer_app\assets\images\ronix_logo.jpg", r"c:\shop\customer_app\assets\images\ronix_logo.png")
    remove_background(r"c:\shop\customer_app\assets\images\ronix_coin.jpg", r"c:\shop\customer_app\assets\images\ronix_coin.png")
    print("Background removal completed using AI (rembg)!")
