package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/bitfield/script"
	"github.com/kylelemons/go-gypsy/yaml"
)

func main() {
	//define the valid commands
	validCommands := []string{"precache", "flash"}

	//parse flags and basic validation on subcommands
	flag.Parse()
	if len(flag.Args()) < 1 {
		fmt.Println("subcommand is missing, one of", validCommands)
		os.Exit(1)
	}
	command := flag.Args()[0]
	if !contains(validCommands, command) {
		fmt.Println("invalid subcommand, should be one of", validCommands)
		os.Exit(1)
	}

	// read config file
	var file = flag.String("config", "config.yaml", "config file to read")
	config, err := yaml.ReadFile(*file)
	if err != nil {
		log.Fatalf("readfile(%q): %s", *file, err)
	}

	//get config value for workDir
	workDir, err := config.Get("workDir")
	if err != nil {
		workDir = "/tmp/kubepi"
	}

	if command == "precache" {
		// get the value for the imageUrl
		imageUrl, err := config.Get("imageUrl")
		if err != nil {
			log.Fatal("Error: no imageUrl specified in config")
		}
		precache(workDir, imageUrl)
	}

	if command == "flash" {
		if len(flag.Args()) < 2 {
			fmt.Println("flash is missing node paramter")
			os.Exit(1)
		}
		nodeName := flag.Args()[1]

		node, err := yaml.Child(config.Root, fmt.Sprintf("nodes.%s.hostname", nodeName))
		// node, err := config.Get(fmt.Sprintf("nodes.%s.hostname", nodeName))
		if err != nil {
			log.Panicf("could not find configured node '%s' in config file: %s", nodeName, err)
		}
		log.Println("flashing for node", node)
	}
}

func contains(s []string, str string) bool {
	for _, v := range s {
		if v == str {
			return true
		}
	}

	return false
}

func precache(workDir string, imageUrl string) {
	cachedImage := workDir + "/cached.img"
	cachedImageXz := workDir + "/cached.img.xz"
	log.Printf("Precache and extract %s to %s", imageUrl, cachedImage)

	_, err := os.Stat(cachedImage)
	if !os.IsNotExist(err) {
		log.Printf("Image already exists. Remove %s and rerun", cachedImage)
		return
	}

	_, err = os.Stat(workDir)
	if os.IsNotExist(err) {
		os.Mkdir(workDir, os.FileMode(744))
	}

	log.Println("Getting image with curl")
	_, err = script.Exec(fmt.Sprintf("curl -s --output %s %s", cachedImageXz, imageUrl)).Bytes()
	if err != nil {
		log.Fatalf("Error: %s", err)
	}

	log.Println("extracting with xz")
	_, err = script.Exec(fmt.Sprintf("xz -d %s", cachedImageXz)).Bytes()
	if err != nil {
		log.Fatalf("Error: %s", err)
	}

	_, err = os.Stat(cachedImage)
	if os.IsNotExist(err) {
		log.Fatalf("Error: file has not been created")
	}
	log.Println("image precached!")
}

func flash()
