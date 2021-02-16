package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
)

type Configuration struct {
	VarDir       string
	SqliteFile   string
	CliConfigDir string
	RearLogDir   string
	Certificate  string
	Key          string
}

var configDRLM Configuration

func getVarValue(configLine, varName string) (bool, string) {
	found := false
	foundVAR := ""
	tempoVAR := ""

	if strings.Contains(configLine, varName) {
		// Remove the text behind #
		tempoVAR = strings.TrimSpace(strings.Split(configLine, "#")[0])
		if tempoVAR != "" {
			// if the name behind the = is equal the varName
			if strings.TrimSpace(strings.Split(tempoVAR, "=")[0]) == varName {
				// Get the text behind =
				tempoVAR = strings.TrimSpace(strings.Split(tempoVAR, "=")[1])
				// remove "
				tempoVAR = strings.Replace(tempoVAR, "\"", "", -1)
				// if is not empty assignt to return
				found = true
				foundVAR = tempoVAR
			}
		}
	}
	return found, foundVAR
}

func getConfigFileVar(configFile, varName string) (bool, string) {

	f, e := os.Open(configFile)
	if e != nil {
		fmt.Println(e.Error())
	}
	defer f.Close()

	found := false
	foundVAR := ""

	// Splits on newlines by default.
	scanner := bufio.NewScanner(f)

	for scanner.Scan() {
		if searchFound, tempoVAR := getVarValue(scanner.Text(), varName); searchFound {
			found = true
			foundVAR = tempoVAR
		}
	}

	if err := scanner.Err(); err != nil {
		// Handle the error
	}

	return found, foundVAR
}

func getStringVar(configuration, varName string) (bool, string) {

	found := false
	foundVAR := ""

	// Splits on newlines by default.
	scanner := bufio.NewScanner(strings.NewReader(configuration))

	for scanner.Scan() {
		if searchFound, tempoVAR := getVarValue(scanner.Text(), varName); searchFound {
			found = true
			foundVAR = tempoVAR
		}
	}

	if err := scanner.Err(); err != nil {
		// Handle the error
	}

	return found, foundVAR
}

func loadDRLMConfiguration() {
	// Find value for VAR_DIR //////
	if found, tmpValue := getConfigFileVar("/usr/share/drlm/conf/default.conf", "VAR_DIR"); found {
		configDRLM.VarDir = tmpValue
	}
	if found, tmpValue := getConfigFileVar("/etc/drlm/local.conf", "VAR_DIR"); found {
		configDRLM.VarDir = tmpValue
	}
	if found, tmpValue := getConfigFileVar("/etc/drlm/site.conf", "VAR_DIR"); found {
		configDRLM.VarDir = tmpValue
	}
	configDRLM.VarDir = strings.Replace(configDRLM.VarDir, "$DRLM_DIR_PREFIX", "", -1)
	///////////////////////////////////////

	// Find value for DB_PATH //////
	if found, tmpValue := getConfigFileVar("/usr/share/drlm/conf/default.conf", "DB_PATH"); found {
		configDRLM.SqliteFile = tmpValue
	}
	if found, tmpValue := getConfigFileVar("/etc/drlm/local.conf", "DB_PATH"); found {
		configDRLM.SqliteFile = tmpValue
	}
	if found, tmpValue := getConfigFileVar("/etc/drlm/site.conf", "DB_PATH"); found {
		configDRLM.SqliteFile = tmpValue
	}
	configDRLM.SqliteFile = strings.Replace(configDRLM.SqliteFile, "$VAR_DIR", configDRLM.VarDir, -1)
	///////////////////////////////////////

	// Set Certificate and Key path
	configDRLM.Certificate = "/etc/drlm/cert/drlm.crt"
	configDRLM.Key = "/etc/drlm/cert/drlm.key"

	// Find value for CLI_CONF_DIR //////
	if found, tmpValue := getConfigFileVar("/usr/share/drlm/conf/default.conf", "CLI_CONF_DIR"); found {
		configDRLM.CliConfigDir = tmpValue
	}
	if found, tmpValue := getConfigFileVar("/etc/drlm/local.conf", "CLI_CONF_DIR"); found {
		configDRLM.CliConfigDir = tmpValue
	}
	if found, tmpValue := getConfigFileVar("/etc/drlm/site.conf", "CLI_CONF_DIR"); found {
		configDRLM.CliConfigDir = tmpValue
	}
	///////////////////////////////////////

	// Find value for REAR_LOG_DIR ////////
	if found, tmpValue := getConfigFileVar("/usr/share/drlm/conf/default.conf", "REAR_LOG_DIR"); found {
		configDRLM.RearLogDir = tmpValue
	}
	if found, tmpValue := getConfigFileVar("/etc/drlm/local.conf", "REAR_LOG_DIR"); found {
		configDRLM.RearLogDir = tmpValue
	}
	if found, tmpValue := getConfigFileVar("/etc/drlm/site.conf", "REAR_LOG_DIR"); found {
		configDRLM.RearLogDir = tmpValue
	}
	///////////////////////////////////////
}

func printDRLMConfiguration() {
	fmt.Println("==============================")
	fmt.Println("=== DRLM API CONFIGURATION ===")
	fmt.Println("==============================")
	fmt.Println("VAR_DIR=" + configDRLM.VarDir)
	fmt.Println("DB_PATH=" + configDRLM.SqliteFile)
	fmt.Println("CLI_CONF_DIR=" + configDRLM.CliConfigDir)
	fmt.Println("REAR_LOG_DIR=" + configDRLM.RearLogDir)
	fmt.Println("DRLM_CERT=" + configDRLM.Certificate)
	fmt.Println("DRLM_KEY=" + configDRLM.Key)
	fmt.Println("")
}

func sendConfigFile(w http.ResponseWriter, file string) {
	if _, err := os.Stat(file); err == nil {
		f, err := ioutil.ReadFile(file) // just pass the file name
		check(err)
		w.Write(f)
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusOK)
	} else {
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusNotFound)
	}
}

func (c *Client) sendConfig(w http.ResponseWriter, configName string) {
	defaultConfig := c.generateDefaultConfig(configName)
	tmpDefaultConfig := ""
	configFileName := ""
	found := false

	if configName == "default" {
		configFileName = configDRLM.CliConfigDir + "/" + c.Name + ".cfg"
	} else {
		configFileName = configDRLM.CliConfigDir + "/" + c.Name + ".cfg.d/" + configName + ".cfg"
	}
	f, e := os.Open(configFileName)
	if e != nil {
		fmt.Println(e.Error())
		w.Header().Set("Content-Type", "text/html")
		w.WriteHeader(http.StatusNotFound)
		return
	}
	defer f.Close()

	// Splits on newlines by default.
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(strings.Split(scanner.Text(), "#")[0])
		if line != "" {
			// Have a new line from config file get the var name
			varName := strings.TrimSpace(strings.Split(line, "=")[0])

			scannerDefault := bufio.NewScanner(strings.NewReader(defaultConfig))
			for scannerDefault.Scan() {
				defaultVarName := strings.TrimSpace(strings.Split(scannerDefault.Text(), "=")[0])
				// for line in default config if is diferent from var name attach to temp default config
				if varName != defaultVarName || varName[len(varName)-1] == '+' {
					tmpDefaultConfig += scannerDefault.Text() + "\n"
				} else {
					tmpDefaultConfig += strings.TrimSpace(scanner.Text()) + "\n"
					found = true
				}
			}
			// attach var line at the end com temp default config
			if !found {
				tmpDefaultConfig += strings.TrimSpace(scanner.Text()) + "\n"
			}
			defaultConfig = tmpDefaultConfig
			tmpDefaultConfig = ""
			found = false
		}
	}

	w.Write([]byte(defaultConfig))
	w.Header().Set("Content-Type", "text/html")
	w.WriteHeader(http.StatusOK)
}
