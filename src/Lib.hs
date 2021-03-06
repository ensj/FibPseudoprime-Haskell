module Lib
    ( 
    classicFib, 
    fib,
    fibPsp,
    fibPspNoFactors,
    scndFermatPspTest,
    carlTest,
    carlTestTermLimits
    ) where

import Sort ( cleanList, subsets, splitByLength, cartesianProduct, removeDuplicates )
import TimeLimits
import Data.List ( foldl' )
import Data.Bits ( Bits(testBit) )
import Math.NumberTheory.Primes (factorise, unPrime)
import Math.NumberTheory.Powers.Modular

-- classic recursive implementation of the fibonacci numbers.
fibs :: [Integer]
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

classicFib :: Int -> Integer 
classicFib n = fibs!!n

-- fastest fib number calculator in the west. We kind of have no idea how this works.
fib :: Int -> Integer
fib n = snd . foldl_ fib_ (1, 0) . dropWhile not $
            [testBit n k | k <- let s = n in [s-1,s-2..0]]    
    where
        fib_ (f, g) p
            | p         = (f*(f+2*g), ss)
            | otherwise = (ss, g*(2*f-g))
            where ss = f*f+g*g
        foldl_ = foldl' -- '

-- generate fibpsp for the nth fib number
fibPsp :: Int -> ([Integer], [Integer])
fibPsp n = 
    (pfFiltered, psp) where
        --Calculate n-th Fibonacci number
        fibn = fib n

        --Get factors for n-th Fibonacci number
        primeFactors = map (\(a, b) -> unPrime a) $ factorise(fibn)
        ntoi = toInteger(n)

        -- calculates the prime factors of fib(n) that are +-1 mod n
        pfFiltered = filter (\factor -> (factor `mod` ntoi == 1) || (factor `mod` ntoi == (ntoi - 1))) primeFactors

        -- clean factors to ([+- 1 mod 5], [+- 2 mod 5])
        cl = cleanList pfFiltered

        -- get all multiples of [+- 1 mod 5] factors
        oneModFiveSets = map product $ filter (\set -> set /= []) $ subsets $ fst cl

        -- get all odd multiples of [+- 2 mod 5] factors
        (singleton, oddMultiple) = splitByLength $ filter (\set -> set /= []) $ subsets $ snd cl

        -- the concatenation of the cartesian product of oneModFive and singleton, 
        -- the odd products by themselves, and the cartesian product of singleton and
        -- the odd products themselves form the list of fibonacci pseudoprimes.
        psp = removeDuplicates $ 
                concat [cartesianProduct(singleton, oneModFiveSets), 
                        cartesianProduct(oddMultiple, oneModFiveSets), 
                        oddMultiple]

-- generate fibpsp for the nth fib number, but quit factorization in the middle if necessary
fibPspTermLimits :: Int -> IO ([Integer], [Integer])
fibPspTermLimits n = do
        let fibn = fib n

        primeFactors <- timeLimited (30 * 60 * 1000000) n $ factorise(fibn) -- init to 1 hour limit
        let pfactorsMapped = map (\(a, b) -> unPrime a) primeFactors
        let ntoi = toInteger(n)

        let pfFiltered = filter (\factor -> (factor `mod` ntoi == 1) || (factor `mod` ntoi == (ntoi - 1))) pfactorsMapped

        let cl = cleanList pfFiltered

        let oneModFiveSets = map product $ filter (\set -> set /= []) $ subsets $ fst cl

        let (singleton, oddMultiple) = splitByLength $ filter (\set -> set /= []) $ subsets $ snd cl

        let psp = removeDuplicates $ 
                concat [cartesianProduct(singleton, oneModFiveSets), 
                        cartesianProduct(oddMultiple, oneModFiveSets), 
                        oddMultiple]
        return (pfFiltered, psp)

-- VERSION FOR BENCHMARK TESTING --
fibPspNoFactors :: (Int, Integer, [Integer]) -> ([Integer], [Integer])
fibPspNoFactors (n, fibn, factors) = 
    (pfFiltered, psp) where
        ntoi = toInteger(n)
        pfFiltered = filter (\factor -> (factor `mod` ntoi == 1) || (factor `mod` ntoi == ntoi - 1)) factors
        cl = cleanList pfFiltered
        oneModFiveSets = map product $ filter (\set -> set /= []) $ subsets $ fst cl
        (singleton, oddMultiple) = splitByLength $ filter (\set -> set /= []) $ subsets $ snd cl
        psp = removeDuplicates $ 
                concat [cartesianProduct(singleton, oneModFiveSets), 
                        cartesianProduct(oddMultiple, oneModFiveSets), 
                        oddMultiple]

-- takes in power and modulus to return result of 2^power `mod` modulus
scndFermatPspTest :: Integer -> Integer
scndFermatPspTest m = powMod 2 (m-1) m

-- Calculates the nth fib number, its fibpsp's, and the base-2 psp & fibpsp's. 
carlTest :: Int -> (Int, [Integer], [(Integer, Integer)])
carlTest n = 
    (n, factors, fibpspChecked) where
        (factors, fibpsp) = fibPsp n
        fibpspChecked = map (\psp -> (psp, scndFermatPspTest psp)) fibpsp

-- Calculates the nth fib number, its fibpsp's, and the base-2 psp & fibpsp's. 
-- quits factorization in the middle if necessary.
carlTestTermLimits :: Int -> IO (Int, [Integer], [(Integer, Integer)])
carlTestTermLimits n = do
    (factors, fibpsp) <- fibPspTermLimits n
    let fibpspChecked = map (\psp -> (psp, scndFermatPspTest psp)) fibpsp
    return (n, factors, fibpspChecked)


