# frozen_string_literal: true

describe 'Our simple database' do # rubocop:disable Metrics/BlockLength
  subject(:execute_commands) do
    output = nil
    IO.popen('./db.out', 'r+') do |pipe|
      commands.each do |command|
        pipe.puts(command)
      end

      pipe.close_write
      output = pipe.gets(nil)
    end
    output.split("\n")
  end

  context 'when using insert and retrieve commands' do
    let(:commands) do
      [
        'insert 1 user1 person1@example.com',
        'select',
        '.exit'
      ]
    end

    let(:expected_result) do
      [
        'db > Executed.',
        'db > (1, user1, person1@example.com)',
        'Executed.',
        'db > '
      ]
    end

    it 'inserts and retrieves a row' do
      expect(execute_commands).to match_array(expected_result)
    end
  end

  context 'when table is full after inserts' do
    let(:commands) do
      (1..1401).map do |i|
        "insert #{i} user#{i} person#{i}@example.com"
      end + ['.exit']
    end
    let(:expected_error_message) { 'db > Error: Table full.' }

    it 'prints an error message' do
      expect(execute_commands[-2]).to eq(expected_error_message)
    end
  end
end
