<#
.SYNOPSIS
Text Generation Script.

.DESCRIPTION
This script provides functions for converting text into a model and generating random text based on the model.

.FUNCTIONS
1. Convert-TextToModel:
   Converts a block of text into a model by cleaning the text, splitting it into words, and creating a hashtable.

2. GenerateTextFromModel:
   Generates random text based on a given model by selecting the next word based on the previous words in the generated text.

3. Get-WeightedRandomWord:
   Selects a weighted random word from a list based on the provided counts.

4. GenerateSecureRandomNumber:
   Generates a secure random number within a specified range.

.PARAMETERS
- Convert-TextToModel:
    - Text (string): The block of text to convert into a model.

- GenerateTextFromModel:
    - SeedWord (string): The starting word for generating the text.
    - MaxWords (int): The maximum number of words to generate.
    - MinNgramOrder (int): The minimum nGram order for generating text. Defaults to 2.
    - MaxNgramOrder (int): The maximum nGram order for generating text. Defaults to 2.
    - K (double): The weighting factor for word selection. Defaults to 1.
    - NumAlternatives (int): The number of alternative words to consider. Defaults to 1.
    - Model (hashtable): The model containing phrases and next word options.

- Get-WeightedRandomWord:
    - Words (string[]): The list of words to select from.
    - K (double): The weighting factor for word selection. Defaults to 1.
    - NumAlternatives (int): The number of alternative words to consider. Defaults to 1.

- GenerateSecureRandomNumber:
    - Minimum (int): The minimum value of the random number.
    - Maximum (int): The maximum value of the random number.

.EXAMPLE
$Text = Get-Content -Path 'D:\path\to\textfile.txt' | Out-String
$Model = Convert-TextToModel -Text $Text
$GeneratedText = GenerateTextFromModel -SeedWord "I like" -MaxWords 50 -MinNgramOrder 2 -MaxNgramOrder 3 -K 0.5 -NumAlternatives 2 -Model $Model
if ($GeneratedText) {
    Write-Output $GeneratedText
}

.NOTES
Author: GPT, Wojciech Napierała
Date: 06.07.2023
Version: 1.0
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
            throw [ArgumentNullException]::new("The text cannot be empty.")
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
    Version: 2.1
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
        [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]] $Model
    )

    try {
        # Validate input parameters
        if ([string]::IsNullOrEmpty($SeedWord)) {
            throw [ArgumentNullException]::new("The seed word cannot be empty.")
        }

        if ($MaxWords -lt 1) {
            throw [ArgumentOutOfRangeException]::new("The maximum number of words must be greater than or equal to 1.")
        }

        if ($MinNgramOrder -gt $MaxNgramOrder) {
            throw [ArgumentException]::new("The minimum nGram order cannot be greater than the maximum nGram order.")
        }

        $generatedText = [System.Text.StringBuilder]::new()
        $currentWords = $SeedWord -split '\s+'

        for ($i = 1; $i -lt $MaxWords; $i++) {
            $nGramOrder = Get-Random -Minimum $MinNgramOrder -Maximum ($MaxNgramOrder + 1)
            $nGramKey = $currentWords[-$nGramOrder..-1] -join " "

            if ($Model.TryGetValue($nGramKey, [ref]$nextWords) -and $nextWords) {
                $nextWord = Get-WeightedRandomWord -Words $nextWords -K $K -NumAlternatives $NumAlternatives
            }
            else {
                $nextWord = Get-WeightedRandomWord -Words $Model.Keys -K $K -NumAlternatives $NumAlternatives
            }

            $generatedText.Append(" $nextWord")
            $currentWords += $nextWord

            if ($currentWords.Count -gt $nGramOrder) {
                $currentWords = $currentWords[-$nGramOrder..-1]
            }
        }

        return $generatedText.ToString().Trim()
    }
    catch {
        Write-Error "Error occurred in GenerateTextFromModel: $_"
        return $null
    }
}

function Get-WeightedRandomWord {
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $Words,

        [double] $K = 1,
        [int] $NumAlternatives = 1
    )

    try {
        $WordCounts = $Words | ForEach-Object {
            [PSCustomObject]@{
                Word  = $_
                Count = $K
            }
        }

        foreach ($WordCount in $WordCounts) {
            $WordCount.Count += ($Model[$WordCount.Word] | Measure-Object).Count
        }

        $TotalCounts = $WordCounts.Count

        $SelectedWords = @()
        $AvailableWords = $WordCounts  # Create a copy of the WordCounts array

        for ($i = 1; $i -le $NumAlternatives; $i++) {
            $RandomIndex = GenerateSecureRandomNumber -Minimum 0 -Maximum $TotalCounts
            $SelectedWord = $AvailableWords[$RandomIndex].Word
            $SelectedWords += $SelectedWord

            # Remove the selected word from the available pool
            $AvailableWords = $AvailableWords | Where-Object { $_.Word -ne $SelectedWord }
            $TotalCounts -= 1  # Update the total count
        }

        return $SelectedWords | Get-Random
    }
    catch {
        Write-Error "Error occurred in Get-WeightedRandomWord: $_"
        return $null
    }
}

function GenerateSecureRandomNumber {
    param (
        [Parameter(Mandatory = $true)]
        [int] $Minimum,

        [Parameter(Mandatory = $true)]
        [int] $Maximum
    )

    try {
        $Rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $ByteArray = New-Object byte[] 4
        $Rng.GetBytes($ByteArray)
        $RandomNumber = [BitConverter]::ToUInt32($ByteArray, 0)

        return $Minimum + ($RandomNumber % ($Maximum - $Minimum))
    }
    catch {
        Write-Error "Error occurred in GenerateSecureRandomNumber: $_"
        return $null
    }
}

$Text = Get-Content -Path 'D:\dane\voytas\Dokumenty\visual_studio_code\github\skryptyVoytasa\TextGenerator2.txt' | Out-String

$Model = Convert-TextToModel -Text $Text

$model

$GeneratedText = GenerateTextFromModel -SeedWord "I like" -MaxWords 20 -MinNgramOrder 2 -MaxNgramOrder 3 -K 0.5 -NumAlternatives 2 -Model $Model

if ($GeneratedText) {
    Write-Output $GeneratedText
}