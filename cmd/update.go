package cmd

import (
	"archive/tar"
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"

	"github.com/spf13/cobra"
)

const (
	owner = "gausszhou"
	repo  = "gru"
)

func init() {
	rootCmd.AddCommand(updateCmd)
}

var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update gru to the latest version",
	RunE: func(cmd *cobra.Command, args []string) error {
		return selfUpdate()
	},
}

func selfUpdate() error {
	ctx, cancel := context.WithTimeout(context.Background(), 30)
	defer cancel()

	latest, err := fetchLatestRelease(ctx)
	if err != nil {
		return fmt.Errorf("failed to check for updates: %w", err)
	}

	if !isNewerVersion(latest, version) {
		fmt.Printf("Already up-to-date (v%s)\n", version)
		return nil
	}

	assetName := buildAssetName()
	assetURL := fmt.Sprintf("https://github.com/%s/%s/releases/download/%s/%s", owner, repo, latest, assetName)

	fmt.Printf("Downloading gru %s...\n", latest)
	archive, err := downloadAsset(ctx, assetURL)
	if err != nil {
		return fmt.Errorf("failed to download update: %w", err)
	}
	defer archive.Close()

	fmt.Println("Extracting...")
	exe, err := extractBinary(archive, assetName)
	if err != nil {
		return fmt.Errorf("failed to extract binary: %w", err)
	}
	defer os.Remove(exe)

	current, err := os.Executable()
	if err != nil {
		return fmt.Errorf("failed to get current executable path: %w", err)
	}

	if err := replaceBinary(exe, current); err != nil {
		return fmt.Errorf("failed to replace binary: %w", err)
	}

	fmt.Printf("Successfully updated to v%s\n", latest)
	return nil
}

func fetchLatestRelease(ctx context.Context) (string, error) {
	url := fmt.Sprintf("https://api.github.com/repos/%s/%s/releases/latest", owner, repo)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "gru-updater/1.0")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("GitHub API returned %s", resp.Status)
	}

	var result struct {
		TagName string `json:"tag_name"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}
	if result.TagName == "" {
		return "", fmt.Errorf("no releases found")
	}
	return result.TagName, nil
}

func isNewerVersion(tag, current string) bool {
	if current == "dev" {
		return true
	}
	a := strings.TrimPrefix(tag, "v")
	b := strings.TrimPrefix(current, "v")
	pa := parseVersion(a)
	pb := parseVersion(b)
	for i := 0; i < 3; i++ {
		if pa[i] != pb[i] {
			return pa[i] > pb[i]
		}
	}
	return false
}

func parseVersion(v string) [3]int {
	parts := strings.SplitN(v, ".", 3)
	var ver [3]int
	for i := range ver {
		if i < len(parts) {
			n, _ := strconv.Atoi(parts[i])
			ver[i] = n
		}
	}
	return ver
}

func buildAssetName() string {
	ext := "tar.gz"
	if runtime.GOOS == "windows" {
		ext = "zip"
	}
	return fmt.Sprintf("gru-%s-%s.%s", runtime.GOOS, runtime.GOARCH, ext)
}

func downloadAsset(ctx context.Context, url string) (io.ReadCloser, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "gru-updater/1.0")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("download returned %s", resp.Status)
	}
	return resp.Body, nil
}

func extractBinary(r io.Reader, assetName string) (string, error) {
	if strings.HasSuffix(assetName, ".tar.gz") {
		return extractTarGz(r)
	}
	if strings.HasSuffix(assetName, ".zip") {
		return extractZip(r)
	}
	return "", fmt.Errorf("unsupported archive format: %s", assetName)
}

func extractTarGz(r io.Reader) (string, error) {
	gr, err := gzip.NewReader(r)
	if err != nil {
		return "", err
	}
	defer gr.Close()

	tr := tar.NewReader(gr)
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return "", err
		}
		if hdr.Typeflag != tar.TypeReg {
			continue
		}
		name := filepath.Base(hdr.Name)
		if name != "gru" && name != "gru.exe" {
			continue
		}
		tmp, err := os.CreateTemp("", "gru-*"+filepath.Ext(name))
		if err != nil {
			return "", err
		}
		if _, err := io.Copy(tmp, tr); err != nil {
			tmp.Close()
			os.Remove(tmp.Name())
			return "", err
		}
		tmp.Close()
		if err := os.Chmod(tmp.Name(), 0o755); err != nil {
			os.Remove(tmp.Name())
			return "", err
		}
		return tmp.Name(), nil
	}
	return "", fmt.Errorf("binary not found in archive")
}

func extractZip(r io.Reader) (string, error) {
	return "", fmt.Errorf("zip extraction not implemented; please use manual update on Windows")
}

func replaceBinary(src, dst string) error {
	srcInfo, err := os.Stat(src)
	if err != nil {
		return err
	}
	if runtime.GOOS == "windows" {
		newPath := dst + ".new.exe"
		if err := copyFile(src, newPath, srcInfo.Mode()); err != nil {
			return err
		}
		fmt.Printf("New binary downloaded to %s\n", newPath)
		fmt.Printf("Please run: move /Y \"%s\" \"%s\"\n", newPath, dst)
		return nil
	}
	if err := copyFile(src, dst, srcInfo.Mode()); err != nil {
		return err
	}
	return nil
}

func copyFile(src, dst string, mode os.FileMode) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	tmp, err := os.CreateTemp(filepath.Dir(dst), ".gru-*")
	if err != nil {
		return err
	}
	tmpName := tmp.Name()

	if _, err := io.Copy(tmp, in); err != nil {
		tmp.Close()
		os.Remove(tmpName)
		return err
	}
	if err := tmp.Chmod(mode); err != nil {
		tmp.Close()
		os.Remove(tmpName)
		return err
	}
	tmp.Close()

	if err := os.Rename(tmpName, dst); err != nil {
		os.Remove(tmpName)
		return err
	}
	return nil
}
