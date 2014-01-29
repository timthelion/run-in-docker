{-# LANGUAGE PackageImports #-}

module Test.Docker
 (runInDocker)
 where

{- imports -}
import "base" System.Environment
 (getProgName
 ,getArgs
 ,withArgs)

import "base" System.Exit
 (exitWith)

import "base" Data.Maybe
 (fromJust)

import "base" System.IO
 (hGetContents
 ,hClose)

import "filepath" System.FilePath
 ((</>))

import "FindBin" System.Environment.FindBin
 (getProgPath)

import qualified "bytestring" Data.ByteString.Lazy.Char8 as BS
 (readFile
 ,hPut)

import "process" System.Process
 (createProcess
 ,proc
 ,StdStream(CreatePipe)
 ,CreateProcess(std_in,std_out,std_err)
 ,waitForProcess)

import "posix-escape" System.Posix.Escape
 (escapeMany)

----------------------------------------------------------------
runInDocker
 :: String
 -- ^ Name of docker image to work from
 -> IO ()
 -- ^ What to run
 -> IO ()

runInDocker from action = do
 args <- getArgs
 case args of
  ("--in-docker":args') -> do
   withArgs args' action
  _ -> do
   progDir <- getProgPath
   progName <- getProgName
   let progPath = progDir </> progName
   progBin <- BS.readFile progPath
   (inhM, outhM,errhM,handle ) <- createProcess dockerProcess
   let
    inh  = fromJust inhM
    outh = fromJust outhM
    errh = fromJust errhM
   BS.hPut inh progBin
   hClose inh
   out <- hGetContents outh
   err <- hGetContents errh
   putStrLn out
   putStrLn err
   code <- waitForProcess handle
   exitWith code
   where
    dockerProcess :: CreateProcess
    dockerProcess =
     (proc "sudo" ("docker":dockerArgs))
     {std_in  = CreatePipe
     ,std_out = CreatePipe
     ,std_err = CreatePipe
     }
    dockerArgs, commandToRunInDocker :: [String]
    dockerArgs =
     ["run"
     ,"-rm"
     ,"-i"
     ,from] ++ commandToRunInDocker
    commandToRunInDocker =
     ["bash"
     ,"-c"
     ,   "cd ; cat > test ; chmod +x test ; ./test --in-docker "
      ++ escapeMany args]