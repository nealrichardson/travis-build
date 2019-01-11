describe 'travis_setup_go', integration: true do
  include SpecHelpers::BashFunction

  let(:go_version) { '1.7.6' }
  let(:go_import_path) { 'github.com/travis-ci-examples/go-example' }

  let :script_header do
    <<~BASH
      source /tmp/tbb/travis_vers2int.bash

      gimme() {
        if [[ $# -eq 0 ]]; then
          if [[ "${GIMME_FAILS}" ]]; then
            echo NO >&2
            return 99
          else
            echo "export GOROOT='set-by-gimme';"
            echo "go version >&2;"
            return 0
          fi
        fi

        if [[ "${1}" == -r ]]; then
          echo "${GIMME_GO_VERSION:-#{go_version}}"
        fi
      }

      travis_cmd() { COMMANDS_RUN+=("travis_cmd ${*}"); }
      tar() { COMMANDS_RUN+=("tar ${*}"); }
      go() { COMMANDS_RUN+=("go ${*}"); }
      git() { COMMANDS_RUN+=("git ${*}"); }

      COMMANDS_RUN=()
      export TRAVIS_HOME=/tmp
      export TRAVIS_BUILD_DIR=/tmp
    BASH
  end

  it 'is valid bash' do
    expect(run_script('travis_setup_go', '')[:truth]).to be true
  end

  it 'requires a go_import_path positional argument' do
    result = run_script(
      'travis_setup_go',
      %[travis_setup_go #{go_version} ""]
    )
    expect(result[:err].read.strip).
      to include('Missing go_import_path positional argument')
  end

  it 'aborts when gimme fails' do
    result = run_script(
      'travis_setup_go',
      <<~BASH
        #{script_header}
        export GIMME_FAILS=1

        travis_setup_go #{go_version} #{go_import_path}
      BASH
    )
    expect(result[:err].read.strip).to include('Failed to run gimme')
  end

  context 'when go>=1.11' do
    let(:go_version) { '1.11.4' }

    it 'copies sources and sets up GOPATH' do
      result = run_script(
        'travis_setup_go',
        <<~BASH
          #{script_header}

          travis_setup_go #{go_version} #{go_import_path}
          for c in "${COMMANDS_RUN[@]}"; do
            echo "---> ${c}"
          done
        BASH
      )

      expect(result[:err].read).to eq ''
      out = result[:out].read
      expect(out).to match(/travis_cmd export GOPATH.+/)
      expect(out).to match(/travis_cmd export PATH.+/)
      expect(out).to match(/tar -Pxzf .+#{go_import_path}/)
      expect(out).to match(/git config remote\.origin\.url.+/)
    end

    context 'when go.mod is present' do
      it 'ensures GO111MODULE=on is set' do
        result = run_script(
          'travis_setup_go',
          <<~BASH
            #{script_header}

            echo nonempty >"${TRAVIS_BUILD_DIR}/go.mod"
            travis_setup_go #{go_version} #{go_import_path}
            for c in "${COMMANDS_RUN[@]}"; do
              echo "---> ${c}"
            done
          BASH
        )

        expect(result[:err].read).to eq ''
        out = result[:out].read
        expect(out).to match(/travis_cmd export GO111MODULE=on.+/)
      end
    end

    context 'when GO111MODULE=on is set' do
      it 'ensures GO111MODULE=on is set' do
        result = run_script(
          'travis_setup_go',
          <<~BASH
            #{script_header}

            export GO111MODULE=on
            travis_setup_go #{go_version} #{go_import_path}
            for c in "${COMMANDS_RUN[@]}"; do
              echo "---> ${c}"
            done
          BASH
        )

        expect(result[:err].read).to eq ''
        out = result[:out].read
        expect(out).to match(/travis_cmd export GO111MODULE=on.+/)
      end
    end
  end

  context 'when go<1.11' do
    let(:go_version) { '1.6.4' }

    it 'copies sources and sets up GOPATH' do
      result = run_script(
        'travis_setup_go',
        <<~BASH
          #{script_header}

          travis_setup_go #{go_version} #{go_import_path}
          for c in "${COMMANDS_RUN[@]}"; do
            echo "---> ${c}"
          done
        BASH
      )

      expect(result[:err].read).to eq ''
      out = result[:out].read
      expect(out).to match(/travis_cmd export GOPATH.+/)
      expect(out).to match(/travis_cmd export PATH.+/)
      expect(out).to match(/tar -Pxzf .+#{go_import_path}/)
      expect(out).to match(/git config remote\.origin\.url.+/)
    end
  end
end
