# Improved PowerShell Code
$model = @{
    "I like" = @("cats", "dogs","eagles","horses")
    "like cats" = @("and","but")
    "like dogs" = @("because")
    "cats and" = @("dogs","eagles","horses")
    "and dogs" = @("are")
    "dogs are" = @("friendly")
    "are friendly" = @("pets")
    "are pets" = @("that")
    "pets that" = @("bring")
    "that bring" = @("joy")
    "cats but" =@("not")
    "but not" = @("eagles","horses")
    "horses are" = @("friendly")
}

$model = @{
    "Animals are" = @("fascinating", "diverse")
    "are fascinating" = @("creatures", "and have unique adaptations")
    "are diverse" = @("in species", "and habitats")
    "in species" = @("range from mammals", "to reptiles", "to birds", "to fish", "to insects")
    "range from mammals" = @("such as lions", "such as elephants", "such as dolphins", "such as bears", "such as whales")
    "such as lions" = @("are majestic", "are powerful hunters")
    "such as elephants" = @("are intelligent", "have incredible memory")
    "such as dolphins" = @("are highly social", "are known for their acrobatics")
    "such as bears" = @("hibernate in winter", "are excellent climbers")
    "such as whales" = @("are the largest mammals", "migrate long distances")
    "to reptiles" = @("like snakes", "like turtles", "like crocodiles", "like lizards", "like tortoises")
    "like snakes" = @("are legless", "can swallow prey whole")
    "like turtles" = @("have protective shells", "can live for many years")
    "like crocodiles" = @("are ancient predators", "are well-adapted to aquatic life")
    "like lizards" = @("can regrow their tails", "are found in a variety of habitats")
    "like tortoises" = @("have sturdy shells", "move slowly on land")
    "to birds" = @("such as eagles", "such as penguins", "such as parrots", "such as owls", "such as hummingbirds")
    "such as eagles" = @("are powerful flyers", "have excellent eyesight")
    "such as penguins" = @("are flightless", "are adapted to life in cold climates")
    "such as parrots" = @("are known for their mimicry", "are highly intelligent")
    "such as owls" = @("are nocturnal", "have silent flight")
    "such as hummingbirds" = @("have rapid wingbeats", "feed on nectar")
    "to fish" = @("like sharks", "like clownfish", "like salmon", "like angelfish", "like goldfish")
    "like sharks" = @("are apex predators", "have multiple rows of teeth")
    "like clownfish" = @("have a symbiotic relationship with anemones", "are brightly colored")
    "like salmon" = @("undertake long migrations", "are prized for their taste")
    "like angelfish" = @("have striking patterns", "are popular in aquariums")
    "like goldfish" = @("are domesticated pet fish", "come in various colors")
    "to insects" = @("like bees", "like butterflies", "like ants", "like beetles", "like dragonflies")
    "like bees" = @("are important pollinators", "live in complex social colonies")
    "like butterflies" = @("have beautiful wings", "undergo metamorphosis")
    "like ants" = @("work together in colonies", "can carry heavy loads")
    "like beetles" = @("are the most diverse insect group", "have hard outer wings")
    "like dragonflies" = @("are skilled flyers", "have large compound eyes")
}


# Generates text based on a given model
function GenerateTextFromModel {
    param (
        [Parameter(Mandatory = $true)]
        [string] $seedWord,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $maxWords,

        [int] $minNgramOrder = 2,
        [int] $maxNgramOrder = 2,
        [double] $k = 1,
        [int] $numAlternatives = 1
    )

    try {
        # Validate input parameters
        if ($minNgramOrder -gt $maxNgramOrder) {
            throw "Minimum nGram order cannot be greater than maximum nGram order."
        }

        $generatedText = $seedWord
        $currentWords = $seedWord -split '\s+'

        for ($i = 1; $i -lt $maxWords; $i++) {
            $nGramOrder = Get-Random -Minimum $minNgramOrder -Maximum ($maxNgramOrder + 1)
            $nGramKey = $currentWords[-$nGramOrder..-1] -join " "

            $nextWords = $model[$nGramKey]

            if (-not $nextWords) {
                $nextWord = Get-WeightedRandomWord -words $model.Keys -k $k
            }
            else {
                $nextWord = Get-WeightedRandomWord -words $nextWords -k $k -numAlternatives $numAlternatives
            }

            $generatedText += " $nextWord"
            $currentWords += $nextWord

            if ($currentWords.Count -gt $nGramOrder) {
                $currentWords = $currentWords[-$nGramOrder..-1]
            }
        }

        return $generatedText
    }
    catch {
        Write-Error "Error occurred in GenerateTextFromModel: $_"
        return $null
    }
}

# Selects a weighted random word from the given words array
function Get-WeightedRandomWord {
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $words,

        [double] $k = 1,
        [int] $numAlternatives = 1
    )

    try {
        $wordCounts = $words | ForEach-Object {
            [PSCustomObject]@{
                Word = $_
                Count = $k
            }
        }

        foreach ($wordCount in $wordCounts) {
            $wordCount.Count += ($model[$wordCount.Word] | Measure-Object).Count
        }

        $totalCounts = $wordCounts.Count

        $selectedWords = @()
        $availableWords = $wordCounts  # Create a copy of the wordCounts array

        for ($i = 1; $i -le $numAlternatives; $i++) {
            $randomIndex = GenerateSecureRandomNumber -Minimum 0 -Maximum $totalCounts
            $selectedWord = $availableWords[$randomIndex].Word
            $selectedWords += $selectedWord

            # Remove the selected word from the available pool
            $availableWords = $availableWords | Where-Object { $_.Word -ne $selectedWord }
            $totalCounts -= 1  # Update the total count
        }

        return $selectedWords | Get-Random
    }
    catch {
        Write-Error "Error occurred in Get-WeightedRandomWord: $_"
        return $null
    }
}

# Generates a secure random number within the specified range
function GenerateSecureRandomNumber {
    param (
        [Parameter(Mandatory = $true)]
        [int] $Minimum,

        [Parameter(Mandatory = $true)]
        [int] $Maximum
    )

    try {
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $byteArray = New-Object byte[] 4
        $rng.GetBytes($byteArray)
        $randomNumber = [BitConverter]::ToUInt32($byteArray, 0)

        return $Minimum + ($randomNumber % ($Maximum - $Minimum))
    }
    catch {
        Write-Error "Error occurred in GenerateSecureRandomNumber: $_"
        return $null
    }
}

# Usage Example
$generatedText = GenerateTextFromModel -seedWord "Animals" -maxWords 15 -minNgramOrder 3 -maxNgramOrder 3 -k 0.5 -numAlternatives 2

if ($generatedText) {
    Write-Output $generatedText
}
