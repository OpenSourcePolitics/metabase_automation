# Metabase Automation

Metabase Automation is a program written in Ruby and helps to create Metabase models. The aim is to create easily models based on [Decidim](https://github.com/decidim/decidim) needs.

Based on the Metabase API, it helps creating Metabase resources based on YAML config files present in `./cards/decidim_cards` and a `config.yml`

## Installation

This program is not a dedicated gem, you must run it using the `main.rb` file. However we'll probably enhance tests and library and then share it.

First, install dependencies: 
```bash
bundle install
```

Ensure file `main.rb` has the execution rights, if not, add it : 
```bash
chmod +x main.rb
```

Pull the defined submodules

Move `config.yml.example` to `config.yml` and replace placeholders by your configuration.

Don't forget to setup env variables for metabase connection:
```bash
export METABASE_HOST="metabase.example.com" && export METABASE_USERNAME="john@doe.com" && export METABASE_PASSWORD="secretpassword"
```

## Usage

You can easily execute the program with one of these commands : 
```bash
make
# OR 
make run
# OR
bundle exec main.rb
# OR
ruby main.rb
# OR 
./main.rb
```

## Development

For now Metabase Automation simplify operations for our Data team. Please note that the code is not efficient and potential fails are present. 
At the moment, it shouldn't causes specific issues on your Metabase server.


## Contributing

Contributions are welcome, at the moment it is still in development.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Metabase Automation project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/metabase_automation/blob/main/CODE_OF_CONDUCT.md).
