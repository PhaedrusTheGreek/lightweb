package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type model struct {
	viewport viewport.Model
	input    textinput.Model
	history  string
	ready    bool
}

type cmdOutput struct {
	output string
}

func execCmd(input string) tea.Cmd {
	return func() tea.Msg {
		if strings.TrimSpace(input) == "" {
			return cmdOutput{}
		}
		cmd := exec.Command("sh", "-c", input)
		out, err := cmd.CombinedOutput()
		result := string(out)
		if err != nil && result == "" {
			result = err.Error()
		}
		return cmdOutput{output: result}
	}
}

func initialModel() model {
	ti := textinput.New()
	ti.Placeholder = "enter a command..."
	ti.Focus()
	ti.CharLimit = 512

	return model{input: ti}
}

func (m model) Init() tea.Cmd {
	return textinput.Blink
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var (
		tiCmd tea.Cmd
		vpCmd tea.Cmd
	)

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC:
			return m, tea.Quit
		case tea.KeyEnter:
			cmd := m.input.Value()
			if cmd == "" {
				return m, nil
			}
			if cmd == "exit" || cmd == "quit" {
				return m, tea.Quit
			}
			m.history += fmt.Sprintf("> %s\n", cmd)
			m.input.SetValue("")
			m.viewport.SetContent(m.history)
			m.viewport.GotoBottom()
			return m, execCmd(cmd)
		}

	case cmdOutput:
		if msg.output != "" {
			m.history += msg.output
			if !strings.HasSuffix(msg.output, "\n") {
				m.history += "\n"
			}
		}
		m.viewport.SetContent(m.history)
		m.viewport.GotoBottom()
		return m, nil

	case tea.WindowSizeMsg:
		inputHeight := 3
		if !m.ready {
			m.viewport = viewport.New(msg.Width, msg.Height-inputHeight)
			m.viewport.SetContent(m.history)
			m.input.Width = msg.Width - 4
			m.ready = true
		} else {
			m.viewport.Width = msg.Width
			m.viewport.Height = msg.Height - inputHeight
			m.input.Width = msg.Width - 4
		}
	}

	m.input, tiCmd = m.input.Update(msg)
	m.viewport, vpCmd = m.viewport.Update(msg)

	return m, tea.Batch(tiCmd, vpCmd)
}

var separatorStyle = lipgloss.NewStyle().
	Border(lipgloss.NormalBorder(), true, false, false, false).
	BorderForeground(lipgloss.Color("240"))

func (m model) View() string {
	if !m.ready {
		return "initializing..."
	}
	return fmt.Sprintf("%s\n%s", m.viewport.View(), separatorStyle.Render(m.input.View()))
}

func main() {
	p := tea.NewProgram(
		initialModel(),
		tea.WithAltScreen(),
	)
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
