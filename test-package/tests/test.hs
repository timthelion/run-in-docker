import Test.Tasty
import Test.Tasty.HUnit
import Test.Docker (runInDocker)
import Foo (f,directoryContents)
import qualified Data.Set as Set
 (fromList)

main = do
 runInDocker "runInDocker" $ defaultMain tests

tests :: TestTree
tests = testGroup "Tests"
         [testCase "f is 1" $ f @?= 1
         ,testCase "f is 2" $ f @?= 2
         ,testCase "read contents of root directory" $
           do
            rootDirContents <- Set.fromList `fmap` directoryContents "/root/"
            (if Set.fromList [".bashrc",".profile"] == rootDirContents
             then return ()
             else assertFailure "Directory contents didn't match expected contents.")]
