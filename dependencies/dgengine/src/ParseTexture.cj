package dgengine

import cjsfml.graphics.*
import cjsfml.graphics.Image as SFMLImage
import encoding.json.*

public func parseTextureImg(game: Game, elem: JsonObject): ?SFMLImage {
    var img: ?SFMLImage = None

    if (let Some(colorElem) <- elem.get("color")) {
        let size = getVector2uKey(elem, "size", default: game.drawRegionSize)
        if (let Some(colorElem) <- getValidArray(colorElem)) {
            if (colorElem.size() == (Int64(size.x) * Int64(size.y))) {
                let img2 = SFMLImage(size.x, size.y)
                for (j in 0..size.y) {
                    for (i in 0..size.x) {
                        img2.setPixel(i, j, getColorVal(colorElem[Int64(i + j * size.x)]))
                    }
                }
                img = img2
            }
        }
        if (img.isNone()) {
            img = SFMLImage(size.x, size.y, getColorVal(colorElem))
        }
    } else if (let Some(file) <- getValidString(elem, "file")) {
        if (let Some(parseTextureImg) <- Hooks.parseTextureImg) {
            let imgBox = Box(Option<SFMLImage>.None)
            if (parseTextureImg(game, elem, imgBox) == true) {
                return imgBox.value
            }
        }
        if (img.isNone()) {
            let mask = getColorKey(elem, "mask", default: Color.transparent)
            img = ImageUtils.loadImage(file, mask: mask)
            if (let Some(split) <- getValidString(elem, "split")) {
                if (let Some(img2) <- img) {
                    let pieces = getUIntKey(elem, "pieces", default: 1)
                    let splitImg = match (split) {
                        case "horizontal" => ImageUtils.splitImageHorizontal(img2, pieces: pieces)
                        case "vertical" => ImageUtils.splitImageVertical(img2, pieces: pieces)
                        case _ => Option<SFMLImage>.None
                    }
                    if (splitImg.isSome()) {
                        img = splitImg
                        img2.close()
                    }
                }
            }
        }
    }

    if (let Some(elem) <- getValidArray(elem, "trim")) {
        if (let Some(img2) <- img) {
            let trimRect = getIntRectVal(elem)
            let imgSize = img2.size

            if (trimRect.left >= 0 && trimRect.top >= 0 && trimRect.width > 0 && trimRect.height > 0 &&
                trimRect.left + trimRect.width <= Int32(imgSize.x) && trimRect.top + trimRect.height <= Int32(imgSize.y)) {
                let trimImg = SFMLImage(UInt32(trimRect.width), UInt32(trimRect.height))
                trimImg.copy(img2, 0, 0, sourceRect: trimRect)
                img = trimImg
                img2.close()
            }
        }
    }
    return img
}

public func getTextureObj(game: Game, elem: JsonValue): ?Texture {
    if (let JsObject <- elem.kind()) {
        if (let Some(obj) <- parseTextureImg(game, elem.asObject())) {
            try (img = obj) {
                let imgSize = img.size
                if (imgSize.x == 0 || imgSize.y == 0) {
                    return None
                }
                let texture = Texture(img)
                texture.repeated = getBoolKey(elem, "repeat", default: true)
                texture.smooth = getBoolKey(elem, "smooth", default: true)
                return texture
            } catch (ex: Exception) {
                logger.error(ex.toString())
            }
        }
    }
    return None
}

public func parseTextureF(game: Game, elem: JsonValue, getTextureObj: (game: Game, elem: JsonValue) -> ?Texture): Unit {
    if (parseResourceFromId<Texture>(game.resources, elem) == true) {
        return
    }
    let id = parseValidIdOrFile(elem)
    if (id.isEmpty() == true) {
        return
    }
    if (let Some(texture) <- getTextureObj(game, elem)) {
        game.resources.addTexture(id, texture, resourceId: getStringCharKey(elem, "resource"))
    }
}

public func parseTexture(game: Game, elem: JsonValue): Unit {
    parseTextureF(game, elem, getTextureObj)
}
