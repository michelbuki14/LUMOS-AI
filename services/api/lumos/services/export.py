"""
LUMOS AI — Export Service
Handles multi-format export with watermarking and resize.
"""

from PIL import Image, ImageDraw, ImageFont
from typing import Optional, Tuple
import io
import structlog

logger = structlog.get_logger__()


class ExportService:
    """Export images in various formats with options."""
    
    SUPPORTED_FORMATS = ['jpeg', 'png', 'tiff', 'webp', 'avif', 'psd']
    
    def __init__(self, output_dir: str = "./exports"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def export(
        self,
        image: Image.Image,
        format: str = 'jpeg',
        quality: int = 90,
        width: Optional[int] = None,
        height: Optional[int] = None,
        watermark_text: Optional[str] = None,
        watermark_position: str = 'bottom-right',
        watermark_opacity: float = 0.5,
        metadata: Optional[dict] = None,
    ) -> Tuple[bytes, str]:
        """
        Export an image with the specified options.
        
        Returns:
            Tuple of (image_bytes, mime_type)
        """
        if format not in self.SUPPORTED_FORMATS:
            raise ValueError(f"Unsupported format: {format}")
        
        # Resize if needed
        img = self._resize(image, width, height)
        
        # Add watermark if specified
        if watermark_text:
            img = self._add_watermark(img, watermark_text, watermark_position, watermark_opacity)
        
        # Export to bytes
        buffer = io.BytesIO()
        
        if format == 'jpeg':
            # Convert RGBA to RGB for JPEG
            if img.mode == 'RGBA':
                img = img.convert('RGB')
            img.save(buffer, format='JPEG', quality=quality)
            mime_type = 'image/jpeg'
        
        elif format == 'png':
            img.save(buffer, format='PNG', optimize=True)
            mime_type = 'image/png'
        
        elif format == 'tiff':
            img.save(buffer, format='TIFF', compression='tiff_deflate')
            mime_type = 'image/tiff'
        
        elif format == 'webp':
            img.save(buffer, format='WEBP', quality=quality, method=6)
            mime_type = 'image/webp'
        
        elif format == 'avif':
            img.save(buffer, format='AVIF', quality=quality)
            mime_type = 'image/avif'
        
        elif format == 'psd':
            # PSD requires special handling, save as TIFF for now
            img.save(buffer, format='TIFF')
            mime_type = 'image/tiff'
        
        buffer.seek(0)
        return buffer.read(), mime_type
    
    def _resize(
        self,
        image: Image.Image,
        width: Optional[int],
        height: Optional[int],
    ) -> Image.Image:
        """Resize image maintaining aspect ratio."""
        if width is None and height is None:
            return image
        
        original_width, original_height = image.size
        
        if width and height:
            # Exact dimensions
            target_width, target_height = width, height
        elif width:
            # Scale by width
            scale = width / original_width
            target_width = width
            target_height = int(original_height * scale)
        else:
            # Scale by height
            scale = height / original_height
            target_width = int(original_width * scale)
            target_height = height
        
        # Use high-quality downsampling
        return image.resize((target_width, target_height), Image.LANCZOS)
    
    def _add_watermark(
        self,
        image: Image.Image,
        text: str,
        position: str = 'bottom-right',
        opacity: float = 0.5,
    ) -> Image.Image:
        """Add a text watermark to the image."""
        # Create a transparent overlay
        overlay = Image.new('RGBA', image.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        
        # Use a default font (in production, load a TTF font)
        try:
            font = ImageFont.truetype("arial.ttf", int(image.size[1] * 0.03))
        except (IOError, OSError):
            font = ImageFont.load_default()
        
        # Calculate text size and position
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        padding = 20
        
        if position == 'top-left':
            x, y = padding, padding
        elif position == 'top-right':
            x, y = image.size[0] - text_width - padding, padding
        elif position == 'bottom-left':
            x, y = padding, image.size[1] - text_height - padding
        elif position == 'center':
            x, y = (image.size[0] - text_width) // 2, (image.size[1] - text_height) // 2
        else:  # bottom-right
            x, y = image.size[0] - text_width - padding, image.size[1] - text_height - padding
        
        # Draw with opacity
        alpha = int(255 * opacity)
        draw.text((x, y), text, fill=(255, 255, 255, alpha), font=font)
        
        # Composite onto image
        image = image.convert('RGBA')
        result = Image.alpha_composite(image, overlay)
        
        return result.convert('RGB')
    
    def create_zip_export(
        self,
        images: list,
        format: str = 'jpeg',
        quality: int = 90,
    ) -> bytes:
        """Create a ZIP archive of exported images."""
        import zipfile
        
        buffer = io.BytesIO()
        
        with zipfile.ZipFile(buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
            for idx, (image, filename) in enumerate(images):
                img_bytes, _ = self.export(image, format, quality)
                arcname = f"{idx:04d}.{format}"
                zf.writestr(arcname, img_bytes)
        
        buffer.seek(0)
        return buffer.read()
