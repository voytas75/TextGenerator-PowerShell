<# 
The script is used to generate random text based on a given model. The model consists of phrases and corresponding next word options. The script uses this model to generate text by selecting the next word based on the previous words in the generated text.

The purpose of the script is to provide a flexible way to generate text that follows a certain pattern or theme. By adjusting the model and parameters, you can create different variations of the generated text.

In the provided example, the script uses an animal-themed model to generate random sentences about animals. By specifying a seed word and other parameters, you can control the length and characteristics of the generated text.

The script can be used for various purposes, such as:

- Generating sample text for testing or demonstration purposes.
- Creating placeholder content for websites or applications.
- Generating random sentences or paragraphs for creative writing or brainstorming.
- Simulating natural language for chatbots or virtual assistants.

You can adapt the script to different models and themes based on your specific requirements. By customizing the model and parameters, you can generate text that suits your desired context or purpose.

Please note that the provided script is a basic example, and its functionality can be extended or modified to suit specific use cases or requirements.
#>

function Convert-TextToModel {
    <#
    .SYNOPSIS
    Converts a block of text into a model.

    .DESCRIPTION
    The Convert-TextToModel function takes a block of text as input and generates a model by cleaning the text, splitting it into words, and creating a hashtable where keys are phrases and values are arrays of next word options.

    .PARAMETER Text
    Specifies the block of text to convert into a model.

    .EXAMPLE
    $text = @"
    Every year, millions of monarch butterflies fly up to 3,000 miles...
    "@

    $model = Convert-TextToModel -Text $text
    $model

    .NOTES
    Author: GPT, Wojciech Napierała
    Date: 06.07.2023
    Version: 1.3
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Text
    )

    try {
        # Validate input parameters
        if ([string]::IsNullOrEmpty($Text)) {
            throw "The text cannot be empty."
        }

        # Clean the text by removing punctuation and extra whitespaces
        $cleanText = $Text -replace '[^\w\s]', '' -replace '\s+', ' '

        # Split the clean text into individual words using .NET class
        $words = [System.Text.RegularExpressions.Regex]::Split($cleanText, '\s+')

        $model = @{}
        $prevKey = $null

        # Generate the model from the words
        foreach ($word in $words) {
            if ($prevKey) {
                if ($model.ContainsKey($prevKey)) {
                    $model[$prevKey] += @($word)
                }
                else {
                    $model[$prevKey] = @($word)
                }
            }

            $prevKey = $word
        }

        return $model
    }
    catch {
        Write-Error "Error occurred in Convert-TextToModel: $_"
        return $null
    }
}

# Generates text based on a given model
function GenerateTextFromModel {
    <#
    .SYNOPSIS
    Generates random text based on a given model.

    .DESCRIPTION
    The GenerateTextFromModel function generates random text by selecting the next word based on the previous words in the generated text.

    .PARAMETER SeedWord
    Specifies the starting word for generating the text.

    .PARAMETER MaxWords
    Specifies the maximum number of words to generate.

    .PARAMETER MinNgramOrder
    Specifies the minimum nGram order for generating text. Defaults to 2.

    .PARAMETER MaxNgramOrder
    Specifies the maximum nGram order for generating text. Defaults to 2.

    .PARAMETER K
    Specifies the weighting factor for word selection. Defaults to 1.

    .PARAMETER NumAlternatives
    Specifies the number of alternative words to consider. Defaults to 1.

    .PARAMETER Model
    Specifies the model hashtable containing phrases and next word options.

    .EXAMPLE
    $model = @{
        "Animals are" = @("fascinating", "diverse")
        "are fascinating" = @("creatures", "and have unique adaptations")
        # Add more key-value pairs as desired
    }

    $generatedText = GenerateTextFromModel -SeedWord "Animals are" -MaxWords 10 -Model $model
    $generatedText

    .NOTES
    Author: GPT, Wojciech Napierała
    Date: 06.07.2023
    Version: 1.2
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $SeedWord,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $MaxWords,

        [int] $MinNgramOrder = 2,
        [int] $MaxNgramOrder = 2,
        [double] $K = 1,
        [int] $NumAlternatives = 1,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $Model
    )

    try {
        # Validate input parameters
        if ([string]::IsNullOrEmpty($SeedWord)) {
            throw "The seed word cannot be empty."
        }

        if ($MaxWords -lt 1) {
            throw "The maximum number of words must be greater than or equal to 1."
        }

        if ($MinNgramOrder -gt $MaxNgramOrder) {
            throw "The minimum nGram order cannot be greater than the maximum nGram order."
        }

        $generatedText = $SeedWord
        $currentWords = $SeedWord -split '\s+'

        for ($i = 1; $i -lt $MaxWords; $i++) {
            $nGramOrder = Get-Random -Minimum $MinNgramOrder -Maximum ($MaxNgramOrder + 1)
            $nGramKey = $currentWords[-$nGramOrder..-1] -join " "

            $nextWords = $Model[$nGramKey]

            if (-not $nextWords) {
                $nextWord = Get-WeightedRandomWord -Words $Model.Keys -K $K
            }
            else {
                $nextWord = Get-WeightedRandomWord -Words $nextWords -K $K -NumAlternatives $NumAlternatives
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
                Word  = $_
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




$Text = Get-Content -Path .\TextGenerator2.txt | out-string


$model = Convert-TextToModel -text $Text

<# 
$model = @{
    "Animals are" = @("fascinating", "diverse")
    "are fascinating" = @("creatures", "and have unique adaptations")
    "are diverse" = @("in species", "and habitats")
    "in species" = @("range from mammals", "to reptiles", "to birds", "to fish", "to insects")
    "range from mammals" = @("such as lions", "such as elephants", "such as dolphins", "such as bears", "such as whales.")
    "such as lions" = @("are majestic", "are powerful hunters.")
    "such as elephants" = @("are intelligent", "have incredible memory.")
    "such as dolphins" = @("are highly social", "are known for their acrobatics.")
    "such as bears" = @("hibernate in winter", "are excellent climbers.")
    "such as whales" = @("are the largest mammals", "migrate long distances.")
    "to reptiles" = @("like snakes", "like turtles", "like crocodiles", "like lizards", "like tortoises.")
    "like snakes" = @("are legless", "can swallow prey whole.")
    "like turtles" = @("have protective shells", "can live for many years.")
    "like crocodiles" = @("are ancient predators", "are well-adapted to aquatic life.")
    "like lizards" = @("can regrow their tails", "are found in a variety of habitats")
    "like tortoises" = @("have sturdy shells", "move slowly on land.")
    "to birds" = @("such as eagles", "such as penguins", "such as parrots", "such as owls", "such as hummingbirds.")
    "such as eagles" = @("are powerful flyers", "have excellent eyesight.")
    "such as penguins" = @("are flightless", "are adapted to life in cold climates.")
    "such as parrots" = @("are known for their mimicry", "are highly intelligent.")
    "such as owls" = @("are nocturnal", "have silent flight.")
    "such as hummingbirds" = @("have rapid wingbeats", "feed on nectar.")
    "to fish" = @("like sharks", "like clownfish", "like salmon", "like angelfish", "like goldfish.")
    "like sharks" = @("are apex predators", "have multiple rows of teeth.")
    "like clownfish" = @("have a symbiotic relationship with anemones", "are brightly colored.")
    "like salmon" = @("undertake long migrations", "are prized for their taste.")
    "like angelfish" = @("have striking patterns", "are popular in aquariums.")
    "like goldfish" = @("are domesticated pet fish", "come in various colors.")
    "to insects" = @("like bees", "like butterflies", "like ants", "like beetles", "like dragonflies.")
    "like bees" = @("are important pollinators", "live in complex social colonies.")
    "like butterflies" = @("have beautiful wings", "undergo metamorphosis.")
    "like ants" = @("work together in colonies", "can carry heavy loads.")
    "like beetles" = @("are the most diverse insect group", "have hard outer wings.")
    "like dragonflies" = @("are skilled flyers", "have large compound eyes.")
}
#>

# Usage Example
$generatedText = GenerateTextFromModel -seedWord "I like" -maxWords 50 -minNgramOrder 2 -maxNgramOrder 3 -k 0.5 -numAlternatives 2 -Model $model

if ($generatedText) {
    Write-Output $generatedText
}
