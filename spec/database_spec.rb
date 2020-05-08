# frozen_string_literal: true

describe 'Our simple database' do # rubocop:disable Metrics/BlockLength
  before do
    `rm -rf test.db`
  end

  subject(:execute_commands) do
    output = nil
    IO.popen('./db.out test.db', 'r+') do |pipe|
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

  context 'when attempting to inset string of a maximum length' do
    let(:long_username) { 'a' * 32 }
    let(:long_email) { 'a' * 255 }
    let(:commands) do
      [
        "insert 1 #{long_username} #{long_email}",
        'select',
        '.exit'
      ]
    end
    let(:expected_result) { "db > (1, #{long_username}, #{long_email})" }

    it 'inserts it corectly and returns it after select' do
      expect(execute_commands).to include(expected_result)
    end
  end

  context 'when attempting to inset string beyond maximum length' do
    let(:long_username) { 'a' * 33 }
    let(:long_email) { 'a' * 256 }
    let(:commands) do
      [
        "insert 1 #{long_username} #{long_email}",
        'select',
        '.exit'
      ]
    end

    let(:expected_error_message) { 'db > String is too long.' }

    it 'displays a relevant error message' do
      expect(execute_commands).to include(expected_error_message)
    end
  end

  context 'when inserted ID is negative' do
    let(:commands) do
      [
        'insert -1 demash dem@a.sh',
        'select',
        '.exit'
      ]
    end
    let(:expected_error_message) { 'db > ID must be positive.' }

    it 'displays a relevant error message' do
      expect(execute_commands).to include(expected_error_message)
    end
  end

  context 'when records were already inserted' do
    let!(:commands) do
      [
        'insert 1 demash dem@a.sh',
        'select',
        '.exit'
      ]
    end
    let(:expected_output) { 'db > (1, demash, dem@a.sh)' }

    before { execute_commands }

    it 'keeps data after closing the connection to database' do
      commands = ['select', '.exit']

      result = execute_commands
      expect(result).to include(expected_output)
    end
  end

  context 'when attempting to print constants' do
    let(:commands) { ['.constants', '.exit'] }
    let(:expected_result) do
      [
        'db > Constants:',
        'ROW_SIZE: 293',
        'COMMON_NODE_HEADER_SIZE: 6',
        'LEAF_NODE_HEADER_SIZE: 10',
        'LEAF_NODE_CELL_SIZE: 297',
        'LEAF_NODE_SPACE_FOR_CELLS: 4086',
        'LEAF_NODE_MAX_CELLS: 13',
        'db > '
      ]
    end

    it 'prints constants' do
      expect(execute_commands).to match_array(expected_result)
    end
  end

  context 'when attempting to display a tree' do
    let(:commands) do
      [1, 2, 3].map do |i|
        "insert #{i} user#{i} email#{i}@example.com"
      end + ['.btree', '.exit']
    end

    let(:expected_result) do
      [
        'db > Executed.',
        'db > Executed.',
        'db > Executed.',
        'db > Tree:',
        'leaf (size 3)',
        '  - 0 : 1',
        '  - 1 : 2',
        '  - 2 : 3',
        'db > '
      ]
    end

    it 'displays the tree' do
      expect(execute_commands).to match_array(expected_result)
    end
  end

  context 'when attempting to insert duplicated key' do
    let(:commands) do
      ['insert 1 name email', 'insert 1 name email', 'select', 'exit']
    end

    let(:expected_result) do
      [
        'db > Executed.',
        'db > Error: Duplicate key.',
        'db > (1, user1, person1@example.com)',
        'Executed.',
        'db > '
      ]
    end
  end
end
