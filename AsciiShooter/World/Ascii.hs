module AsciiShooter.World.Ascii where

import Feature
import qualified AsciiShooter.Feature.Position as Position
import AsciiShooter.Utilities.Mechanics
import AsciiShooter.World

import Data.Foldable 
import Data.Array.Diff
import Data.Set (Set)
import Data.List (transpose)
import qualified Data.Set as Set
import Prelude hiding (maximum)

data Color = Red | Green | Blue | Transparent deriving (Eq, Ord, Show)
type Picture = DiffArray (Int, Int) (Char, Color)
data Sprite = Sprite Int Int [((Int, Int), (Char, Color))]

playerColor 1 = Red
playerColor 2 = Green

drawEntity :: Picture -> Entity () -> Game Picture
drawEntity picture entity = case getFeature entity of
    Just feature -> do
        position <- get Position.position feature
        return $ drawTank picture Red (position, North)
    Nothing -> return picture

background :: Integral a => a -> a -> DiffArray (Int, Int) (Char, Color)     
background width height = 
    listArray ((0, 0), (fromIntegral width - 1, fromIntegral height - 1)) (repeat (' ', Transparent))

translatePoints :: (Int, Int) -> [((Int, Int), (Char, Color))] -> [((Int, Int), (Char, Color))]
translatePoints (x, y) sprite = 
    map ((\((x', y'), c) -> ((x + x', y + y'), c))) sprite

projectileAscii = [
    "*"
    ]        
        
tankAsciiNorth = [
    " | ",
    "¤|¤",
    "¤O¤",
    "¤-¤",
    "   "]

tankAsciiEast = [
    " ¤¤¤ ",
    " |o==",
    " ¤¤¤ "]

tankSprite North = toSprite tankAsciiNorth
tankSprite South = toSprite (reverse tankAsciiNorth)
tankSprite West = toSprite (map reverse tankAsciiEast)
tankSprite East = toSprite tankAsciiEast

toSprite :: [String] -> Color -> Sprite 
toSprite lines color = 
    Sprite 
        (width lines) 
        (width (transpose lines)) 
        (filter ((/= ' ') . fst . snd) (toSpriteLines 0 lines))
    where
        width lines = maximum (0 : map length lines)

        toSpriteLines :: Int -> [String] -> [((Int, Int), (Char, Color))]
        toSpriteLines row [] = []
        toSpriteLines row (line : lines) = toSpriteLine 0 row line ++ toSpriteLines (row + 1) lines

        toSpriteLine :: Int -> Int -> String -> [((Int, Int), (Char, Color))]
        toSpriteLine column row [] = []
        toSpriteLine column row (char : line) = ((column, row), (char, color)) : toSpriteLine (column + 1) row line

drawProjectile :: Picture -> Color -> Vector -> Picture
drawProjectile picture playerColor location = 
    drawSprite picture location (toSprite projectileAscii playerColor)

drawTank :: Picture -> Color -> (Vector, Direction) -> Picture
drawTank picture playerColor (location, direction) = 
    drawSprite picture location (tankSprite direction playerColor)

drawWall :: Picture -> Vector -> Vector -> Picture
drawWall picture position size = 
    let (width, height) = (round (vectorX size), round (vectorY size)) in
    let spriteLines = replicate height (replicate width '#') in
    let sprite = toSprite spriteLines Blue in
    drawSprite picture position sprite

drawSprite :: Picture -> Vector -> Sprite -> Picture
drawSprite picture location (Sprite width height points) = 
    let ((x1, y1), (x2, y2)) = bounds picture in
    let withinBounds (x, y) = x1 <= x && x <= x2 && y1 <= y && y <= y2 in
    let (x, y) = toTuple location in
    let points' = translatePoints (x - width `div` 2, y2 - y - height `div` 2) points in
    picture // filter (withinBounds . fst) points'
    
toTuple :: Vector -> (Int, Int)
toTuple vector = (round (vectorX vector), round (vectorY vector))

toVector :: (Int, Int) -> Vector
toVector (x, y) = (fromIntegral x, fromIntegral y)

