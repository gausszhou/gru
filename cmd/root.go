package cmd

import (
	"github.com/spf13/cobra"
)

var version = "dev"

var rootCmd = &cobra.Command{
	Use:     "gru",
	Short:   "Render Markdown to ANSI terminal output",
	Long:    "gru is a fast Markdown-to-ANSI renderer for the terminal.\n\nIt reads a Markdown file and prints colorized, word-wrapped output\nto stdout, with automatic terminal width detection.",
	Version: version,
	Args:    cobra.MinimumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		return renderFile(cmd, args)
	},
}

var (
	width int
	light bool
)

func init() {
	rootCmd.PersistentFlags().IntVarP(&width, "width", "w", 0, "word wrap width (0 = auto-detect)")
	rootCmd.PersistentFlags().BoolVarP(&light, "light", "l", false, "use light theme")
}

func Execute() error {
	return rootCmd.Execute()
}
