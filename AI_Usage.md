## AI Assistance Disclosure
The main AI used was Claude Sonnet 4.5

AI was used to assist with:
- **Documentation**: Writing test descriptions, README sections, and code comments
- **Scripting**: Generating sweep automation structure (bash/Python) and report formatting
- **Analysis**: Identifying potential edge cases and test scenarios

AI limitations encountered:
- **RTL Generation**: AI-proposed VHDL was often not synthesizable or used simulation-only constructs
- **Synthesis vs Simulation**: AI struggled to distinguish between elaboration-time functions (synthesis-friendly) and simulation-only code, particularly for time-to-cycles calculations
- **Design verification**: Manual review and testing was essential to validate all AI-generated code. For example, debugging ANSI parsing issues was not possible with AI

In practice, AI was primarily useful for documentation, aesthetic improvements to scripts, and automating repetitive tasks rather than core RTL development.

I systematically checked with yosys for unsynthesizable code 
