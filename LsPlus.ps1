# Questo script permette di visualizzare informazioni su file e cartelle
# similmente a quanto fatto dall'explorer classico, ma con delle funzioni aggiuntive
#
# Autore: Filippo Zinetti
# Versione: 6.6.2019

param([string]$path, [string]$csv, [string]$log, [string]$liveLog)
$start = (pwd)
#---------------------------------------------------------
#	Funzioni
#---------------------------------------------------------
#controlla la validità di valori del file CSV
function getCsvValue($i) {
	if ($keys -eq $null) {
		#return $defaultValues
		return ($defaultValues[$i]).toUpper()
	} elseif ($keys.Value[$i] -eq $null) {
		return ($defaultValues[$i]).toUpper()
	}
	return $keys.value[$i].toUpper()
}

#formatta una nuova riga di log
function log($msg) {
	if ($liveLog -eq $true) {
		write-host($msg)
	}
	if ($logPath -ne "") {
		add-content $logPath ("[" + (get-date -format dd-MM-yy::HH.mm.ss) + "] " + $msg)
	}
}

#calcola il peso di ogni elemento
function getSize($l) {
	$t1 = get-date
	log("Ricerca informazioni")
	$size = @()
	$count = $l.count
	$index = 0
	#trova e somma il peso di ogni file in ogni cartella
	foreach($e in $l) {
		$index++
		if (-not $e.PSIsContainer) {
			$size += $e.length
			log("Trovato file singolo: " + $e + ", peso: " + $e.length + " byte")
			continue
		}
		$perc = [int]($index * 100 / $count)
		log("Progresso generale " + $index + "/" + $count + " (" + $perc + "%)`n`n")
		log("Cartella di ricerca: " + $e)
		$d = ls $e -recurse -ErrorAction "silentlyContinue"
		if ($d -eq $null) {
			log("Errore di permessi (cartella " + $e + "), ignorata")
			$size += "0"
			continue
		}
		$total = 0
		$count2 = $d.count
		$index2 = 0
		foreach ($i in $d) {
			$name = ""
			(($i.pspath.tocharArray())[(($i.pspath.tocharArray()).count - $i.name.tochararray().count)..($i.pspath.tocharArray()).count]) | foreach {
				$name += $_
			}
			$index2++
			if (-not $i.PSIsContainer) {
				$total += $i.length
			
				#scrive solo se gli elementi non sono troppi
				if (($index2 % 100 -eq 0 -or $count2 -lt 100) -and ($index2 % 1000 -eq 0 -or $count2 -lt 1000)) {
					log("`tElemento $index2/$count2 (" + [int]($index2 * 100 / $count2) + "%), $name, peso: " + $i.length + " byte")
				}
			}
		}
		$size += $total
		log("Aggiunto al totale: " + $total)
	}
	log("Termine scansione")
	$size
}

#raggruppa le colonne di dati in un array di oggetti
function dataToArray($l) {
	$data = @()
	for($i = 0; $i -lt $l.count; $i++) {
		$currentSize = $size[$i]
		$data += New-Object psobject -Property @{
			LastWriteTime=($l[$i].lastWriteTime.toString()); Size=($currentSize); Name=($l[$i].name) }
	}
	$data
}

#cambia il tipo di visualizzazione dei pesi
function scale($currentSize) {
	if ($currentSize -gt 1024 * 1024 * 1024) {
		$currentSize = [string][int]($currentSize / 1024 / 1024 / 1024) + " GB"
	} elseif ($currentSize -gt 1024 * 1024) {
		$currentSize = [string][int]($currentSize / 1024 / 1024) + " MB"
	} elseif ($currentSize -gt 1024) {
		$currentSize = [string][int]($currentSize / 1024) + " KB"
	} else {
		$currentSize = [string]$currentSize + " B"
	}
	$currentSize
}

#legge l'input senza aspettare che venga premuto invio
function getInput() {
	while(-not $pressed) {
		if ($Host.UI.RawUI.KeyAvailable) {
			return $Host.UI.RawUI.ReadKey().Character
		}
	}
}

#scrive i dati trovati a terminale
function writeData() {
write-host("`n   Path: " + (pwd))
	write-host("`n   LastWriteTime   `t Size `t  Name")
	write-host("   ******************* `t ******`t  ****")
	$i = 0
	if ($data.count -eq 0 -or $data.count -eq $null) {
		$count = 1
	} else {
		$count = $data.count
	}
	$cursorLine = ($cursorLine + $count) % $count
	foreach($e in $data) {
		$s = ""
		$size = scale $e.size
		$s += $e.LastWriteTime + "`t " + $size + "`t  " + $e.Name
		if ($i -eq $cursorLine) {
			$s = " > " + $s
			write-host($s) -foregroundColor green
			$i++
			continue
		}
		$s = "   " + $s
		write-host($s)
		$i++
	}
	write-host("`n   [$quit] Quit   [$up] Up   [$down] Down   [$help] Help")
	#return getInput
}

#---------------------------------------------------------
#	Gestione parametri
#---------------------------------------------------------
$logPath = ""
#crea il file log
if ($log -ne "") {
	$logPath = "" + $start + "/LsPlus.log"
	if (-not (Test-Path $logPath)) {
		ni $logPath
	}
}
$livelog = if ($liveLog -eq "") { $false } else { $true }

log("`n`n`n--------------")
log("Script avviato");
#vengono importati i valori del file CSV, se specificato
if ($csv -ne "" -and (Test-Path $csv)) {
	$keys = Import-Csv $csv
	log("Importo gli elementi file CSV " + $csv+ ").")
}
#---------------------------------------------------------
#	Impostazione comandi
#---------------------------------------------------------
$defaultValues = "-","q","h","p","f","b","u","d","c","r","s","l","s","n","y","o","d","f" 
$reload = getCsvValue 0
$quit = getCsvValue 1
$help = getCsvValue 2
$changePath = getCsvValue 3
$forward = getCsvValue 4
$back = getCsvValue 5
$up = getCsvValue 6
$down = getCsvValue 7
$copy = getCsvValue 8
$remove = getCsvValue 9 
$sort = getCsvValue 10
$byLwt = getCsvValue 11
$bySize = getCsvValue 12
$byName = getCsvValue 13
$confirm = getCsvValue 14
$only = getCsvValue 15
$directory = getCsvValue 16
$file = getCsvValue 17
$itemToShow = "a";

$input = $reload
$cursorLine = 0
#---------------------------------------------------------
#	Loop principale
#---------------------------------------------------------
clear
while ($input -ne $quit) {
	#se l'input è reload, non cambiare il percorso
	if ($input -ne $reload) {
		$path = "."
	}
	#gestione di tutti gli input
	if ($input -eq $changePath) {
		write-host("`b`nChoose new path:")
		$path = read-host
			clear
		if (-not (Test-Path $path)) {
			write-host("`nPath not found")
		}
	} elseif ($input -eq $forward) {
		clear
		try {
			$path = "./" + $data[$cursorLine].name
		} catch {
			write-host("`nCannot go forward")
		}
	} elseif ($input -eq $back) {
		clear
		$path = "../"
	} elseif ($input -eq $up) {
		clear
		$cursorLine--
	} elseif ($input -eq $down) {
		clear
		$cursorLine++
	} elseif ($input -eq $copy) {
		write-host("`nDestination:")
		$dest = read-host
		clear
		if (-not (Test-Path $dest)) {
			write("Creating directory and")
		}
		write("copying files...")
		try {
			cp $data[$cursorLine].Name $dest -recurse -ErrorAction "Stop"
		} catch {
			write-host("`nCannot move item to specified destination")
			log("Impossibile spostare l'elemento nella destinazione $dest")
		}
		$input = $reload
	} elseif ($input -eq $sort) {
		write-host("`b `n   Sort: [$byLwt] Last Write Time   [$bySize] Size   [$byName] Name")
		$input = getInput
		try {
			if ($input -eq $byLwt) {
				#ordina per ultima modifica
				$data = $data | sort -Property LastWriteTime
			} elseif ($input -eq $bySize) {
				#ordina per peso
				$data = $data | sort -Property Size
			} elseif ($input -eq $byName) {
				#ordina per nome
				$data = $data | sort -Property Name
			} else {
				$input = "-"
				continue
			}
			write-host("`b `n   Type: [D] Descending   [A] Ascending")
			$input = getInput
			if ($input -eq "d") {
				[array]::Reverse($data)
			} elseif ($input -ne "a") {
				clear
			}
		} catch {
			clear
			write-host("`nCannot sort data")
			log("Errore dell'ordinamento dei dati")
		}
		continue
	} elseif ($input -eq $remove) {
		try {
			rm $data[$cursorLine].name -recurse -confirm
		} catch {
			clear
			write-host("`nCannot remove item")
			log("`bErrore nel rimuovere l'elemento")
		}
		clear
	} elseif ($input -eq $help) {
		write-host("`b `nCommands:`n`n   [$forward] Enter directory/Run file   [$back] Back to parent directory`n`n   [$only] Show only directory/file   [$sort] Sort`n`n   [$changePath] Change path   [$copy] Copy   [$remove]Remove")
		$input = getInput
		clear
		continue
	} elseif ($input -eq $only) {
		write-host("`b  `n   Show only: [$directory] Directory   [$file] File   [A] All")
		$showType = getInput
		if ($showType -eq "a" -or $showType -eq $directory -or $showType -eq $file) {
			$itemToShow = $showType
		}
		clear
	} else {
		clear
	}
	
	#se il percorso non è impostato, viene usata la cartella corrente
	if ($path -eq "" -or -not (Test-Path $path)) {
		$path = (pwd)
	}
	try {
		cd $path -ErrorAction "Stop"
	} catch {
		write-host("`nRun file? ($confirm/N)")
		$run = getInput
		try {
			if ($run -eq $confirm) {
				& $path -ErrorAction "Stop"
			}
		} catch {
			clear
			write-host("`nCannot open this file")
			log("`bErrore nell'aprire il file")
		}
	}
	#se necessario, calcola tutti i nuovi valori
	$l = ""
	$l = ls
	if ($itemToShow -eq $directory) {
		$l = ls | where-object { $_.PSIsContainer }
	} elseif ($itemToShow -eq $file) {
		$l = ls | where-object { -not $_.PSIsContainer }
	}
	if ($input -eq $changePath -or $input -eq $forward -or $input -eq $back -or $input -eq $reload -or $input -eq $only -or $input -eq $remove) {
		$size = getSize($l)
		$data = dataToArray($l)
		$cursorLine = 0
	}
	writeData
	$input = getInput
}
cd $start
