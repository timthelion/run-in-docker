module Foo (f,directoryContents) where
import System.Directory (getDirectoryContents)

f :: Int
f = 1

directoryContents :: FilePath -> IO [FilePath]
directoryContents dir = do
 contents' <- getDirectoryContents dir
 return $ filter (\e->e/="."&&e/="..") contents'