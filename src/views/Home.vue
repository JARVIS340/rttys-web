<template>
  <div>
    <Layout>
      <headerTitles :username="username" :isadmin="isadmin"/>

      <Content>
        <Card icon="md-link">
          <template slot="title">
            {{
              $t('device-count', {
              count: devlists.filter((dev) => dev.online).length,
              })
            }}
          </template>

          <template slot="extra">
            <Input
              style="margin-right: 4px; width: 200px"
              v-model="filterString"
              search
              @input="handleSearch"
              :placeholder="$t('Please enter the filter key')"
            />
          </template>

          <Table
            :loading="loading"
            :columns="columnsDevices"
            :data="filteredDevices"
            stripe
            :no-data-text="$t('No devices connected')"
            @on-selection-change="handleSelection"
            context-menu
            show-context-menu
            @on-contextmenu="handleContextMenu"
          >
            <template slot="contextMenu">
              <DropdownItem @click.native="showCmdForm">
                <Icon type="md-play" />
                {{ $t('Execute command') }}
              </DropdownItem>

              <DropdownItem v-if="isadmin" @click.native="showBindForm">
                <Icon type="md-person-add" />
                {{ $t('Bind user') }}
              </DropdownItem>

              <DropdownItem v-show="isadmin && selection[0] && selection[0].bound" @click.native="unBindUser">
                <Icon type="md-close" />
                {{ $t('Unbind') }}
              </DropdownItem>

              <DropdownItem @click.native="deleteDevices">
                <Icon type="ios-trash"/>
                {{ $t('Clear Offline Device') }}
              </DropdownItem>
            </template>

            <template v-slot:connected="{ row }">
              <span v-if="row.online">{{ row.connected | formatTime }}</span>
            </template>

            <template v-slot:uptime="{ row }">
              <span v-if="row.online">{{ row.uptime | formatTime }}</span>
            </template>

            <template v-slot:action="{ row }">
              <!-- <Button
                v-if="isadmin && row.bound"
                type="warning"
                size="small"
                style="vertical-align: bottom"
                @click="unBindUser(row.id)"
                >{{ $t('Unbind') }}</Button
              > -->
              <Tooltip
                v-if="row.online"
                placement="top"
                :content="$t('Access your device\'s Shell')"
              >
                <Icon
                  type="md-settings"
                  style="font-size: 2rem; color: #515a6e; cursor: pointer"
                />
              </Tooltip>

              <Tooltip
                v-if="row.online"
                placement="top"
                :content="$t('Access your device\'s Shell')"
              >
                <i
                  class="iconfont icon-shell"
                  style="font-size: 2rem; color: black; cursor: pointer"
                  @click="connectDevice(row.id)"
                />
              </Tooltip>

              <Tooltip
                v-if="row.online"
                placement="top"
                :content="$t('Access your devices\'s Web')"
              >
                <i
                  class="iconfont icon-web"
                  style="font-size: 2rem; color: #409eff; cursor: pointer"
                  @click="connectDeviceWeb(row.id)"
                />
              </Tooltip>

              <span v-if="!row.online" style="margin-left: 10px; color: red">{{
                $t('Device offline')
              }}</span>
            </template>
          </Table>
        </Card>

        <Modal v-model="bindUserData.modal" :title="$t('Bind user')" :width="300">
          <Select v-model="bindUserData.currentUser">
            <Option v-for="user in bindUserData.users" :key="user" :value="user">{{ user }}</Option>
          </Select>

          <span slot="footer" class="dialog-footer">
            <Button
              type="primary"
              @click="bindUser"
            >
              {{ $t('OK') }}
            </Button>
          </span>
        </Modal>

        <Modal v-model="cmdStatus.respModal" :title="$t('Response of executive command')" :width="800">
          <Table
              :columns="columnsCmdResp"
              :data="cmdStatus.responses"
              :no-data-text="$t('No Response')"
          />
          <div slot="footer" />
        </Modal>

        <Modal v-model="cmdModal" :title="$t('Execute command')" @on-ok="doCmd">
          <Form
            ref="cmdForm"
            :model="cmdData"
            :rules="cmdRuleValidate"
            :label-width="100"
            label-position="left"
          >
            <FormItem :label="$t('Username')" prop="username">
              <Input v-model="cmdData.username" />
            </FormItem>
            <FormItem :label="$t('Password')" prop="password">
              <Input type="password" v-model="cmdData.password" password />
            </FormItem>
            <FormItem :label="$t('Command')" prop="cmd">
              <Input v-model.trim="cmdData.cmd" />
            </FormItem>
            <FormItem :label="$t('Parameter')" prop="params">
              <Tag
                :key="i"
                v-for="(tag, i) in cmdData.params"
                closable
                @on-close="delCmdParam(tag)"
                >{{ tag }}</Tag
              >
              <Input
                v-if="inputParamVisible"
                style="width: 90px; margin-left: 10px"
                v-model="inputParamValue"
                ref="inputParam"
                size="small"
                @on-enter="handleInputParamConfirm"
                @on-blur="handleInputParamConfirm"
              />
              <Button
                v-else
                style="width: 40px; margin-left: 10px"
                size="small"
                icon="ios-add"
                type="primary"
                @click="showInputParam"
              />
            </FormItem>

            <FormItem :label="$t('Wait Time')" prop="wait">
              <Input v-model.number="cmdData.wait" placeholder="30">
                <template slot="append">s</template>
              </Input>
            </FormItem>
          </Form>
        </Modal>

        <Modal v-model="cmdStatus.modal" :title="$t('Status of executive command')" :closable="false" :mask-closable="false">
          <Progress text-inside :stroke-width="20" :percent="cmdStatusPercent" />
          <p>{{ $t('cmd-status-total', { count: cmdStatus.total }) }}</p>
          <p>{{ $t('cmd-status-fail', { count: cmdStatus.fail }) }}</p>
          <div slot="footer">
            <Button
              type="primary"
              size="large"
              :disabled="cmdStatus.execing > 0"
              @click="showCmdResp"
              >{{ $t('OK') }}</Button
            >
            <Button
              type="error"
              size="large"
              :disabled="cmdStatus.execing === 0"
              @click="ignoreCmdResp"
              >{{ $t('Ignore') }}</Button
            >
          </div>
        </Modal>
      </Content>
    </Layout>
  </div>
</template>

<script>
import ExpandCmdResp from '@/components/ExpandCmdResp'
import headerTitles from './Header.vue'

export default {
  name: 'Home',
  components: {headerTitles},
  data() {
    return {
      username: '',
      loading: true,
      isadmin: false,
      devlists: [],
      selection: [],
      filterString: '',
      filteredDevices: [],
      inputParamVisible: false,
      inputParamValue: '',
      columnsDevices: [{
          title: this.$t('Device ID'),
          key: 'id',
          align: 'left',
          sortable: true,
          minWidth: 150
        }, {
          title: this.$t('Connected time'),
          slot: 'connected',
          align: 'center',
          sortable: true,
          width: 150
        }, {
          title: this.$t('Uptime'),
          slot: 'uptime',
          align: 'center',
          sortable: true,
          width: 150
        }, {
          title: this.$t('Description'),
          key: 'description',
          tooltip: true,
          sortable: true,
          minWidth: 150
        }, {
          slot: 'action',
          align: 'center',
          width: 150,
          fixed: 'right'
        }
      ],
      cmdModal: false,
      cmdStatus: {
        total: 0,
        modal: false,
        execing: 0,
        fail: 0,
        respModal: false,
        responses: []
      },
      cmdData: {
        username: '',
        password: '',
        cmd: '',
        params: [],
        currentParam: '',
        wait: 30
      },
      bindUserData: {
        modal: false,
        users: [],
        currentUser: ''
      },
      cmdRuleValidate: {
        username: [
          { required: true, message: this.$t('username is required') }
        ],
        cmd: [{ required: true, message: this.$t('command is required') }],
        wait: [
          {
            validator: (rule, value, callback) => {
              if (!value) {
                callback();
                return;
              }

              if (!Number.isInteger(value) || value < 0 || value > 30) {
                callback(
                  new Error(this.$t('must be an integer between 0 and 30'))
                );
              }

              callback();
            }
          }
        ]
      },
      columnsCmdResp: [
        {
          type: 'expand',
          width: 50,
          render: (h, params) => {
            return h(ExpandCmdResp, {
              props: {
                stdout: params.row.stdout,
                stderr: params.row.stderr
              }
            });
          }
        },
        {
          title: '#',
          type: 'index',
          width: 100
        },
        {
          title: this.$t('Device ID'),
          key: 'id'
        },
        {
          title: this.$t('Status Code'),
          key: 'code'
        },
        {
          title: this.$t('Error Code'),
          key: 'err'
        },
        {
          title: this.$t('Error Message'),
          key: 'msg'
        }
      ]
    };
  },
  filters: {
    formatTime(t) {
      let ts = t || 0;
      let tm = 0;
      let th = 0;
      let td = 0;

      if (ts > 59) {
        tm = Math.floor(ts / 60);
        ts = ts % 60;
      }

      if (tm > 59) {
        th = Math.floor(tm / 60);
        tm = tm % 60;
      }

      if (th > 23) {
        td = Math.floor(th / 24);
        th = th % 24;
      }

      let s = '';

      if (td > 0) s = `${td}d `;

      return s + `${th}h ${tm}m ${ts}s`;
    }
  },
  timers: {
    update_devices: {
      time: 2000,
      autostart: true,
      immediate: false,
      repeat: true
    }
  },
  computed: {
    cmdStatusPercent() {
      if (this.cmdStatus.total === 0) return 0;
      return (
        ((this.cmdStatus.total - this.cmdStatus.execing) /
          this.cmdStatus.total) *
        100
      );
    }
  },
  methods: {
    update_devices() {
      setTimeout(() => {
        this.getDevices();
      }, 500);
    },
    parseIPv4(x) {
      if (!x.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)) return null;

      if (
        RegExp.$1 > 255 ||
        RegExp.$2 > 255 ||
        RegExp.$3 > 255 ||
        RegExp.$4 > 255
      )
        return null;

      return [+RegExp.$1, +RegExp.$2, +RegExp.$3, +RegExp.$4];
    },
    getDevices() {
      this.axios.get('/devs').then((res) => {
        this.loading = false
        this.devlists = res.data
        // this.selection = []
        this.handleSearch()
      })
      .catch(() => {
        this.$router.push('/login')
      })
    },
    showBindForm() {
      if (this.selection.length < 1) {
        this.$Message.error(
          this.$t('Please select the devices you want to bind')
        );
        return;
      }

      this.axios.get('/users').then((res) => {
        this.bindUserData.users = res.data.users;
        this.bindUserData.modal = true
        this.bindUserData.currentUser = ''
      });
    },
    bindUser() {
      this.bindUserData.modal = false;

      this.axios.post('/bind', {
        devices: this.selection.map((s) => s.id),
        username: this.bindUserData.currentUser
      }).then(() => {
        this.getDevices();
        this.$Message.success(this.$t('Bind success'));
      })
    },
    unBindUser() {
      if (this.selection.length < 1) {
        this.$Message.error(
          this.$t('Please select the devices you want to bind')
        );
        return;
      }

      this.axios
        .post('/unbind', {
          devices: [this.selection[0].id]
        })
        .then(() => {
          this.getDevices();
          this.$Message.success(this.$t('Unbind success'));
        });
    },
    deleteDevices() {
      if (this.selection.length < 1) {
        this.$Message.error(
          this.$t('Please select the devices you want to operate')
        );
        return;
      }

      const offlines = this.selection.filter((s) => !s.online);

      if (offlines.length < 1) {
        this.$Message.info(
          this.$t('There are no offline devices in selected devices')
        );
        return;
      }

      this.axios
        .post('/delete', {
          devices: offlines.map((s) => s.id)
        })
        .then(() => {
          this.getDevices();
          this.$Message.success(this.$t('Delete success'));
        });
    },
    connectDevice(devid) {
      window.open('/rtty/' + devid);
    },
    connectDeviceWeb(devid) {
      let addr = '127.0.0.1';

      this.$Modal.confirm({
        render: (h) => {
          const input = h('Input', {
            props: {
              value: addr,
              autofocus: true,
              placeholder: this.$t(
                'Please enter the address you want to access'
              )
            },
            on: {
              input: (val) => {
                addr = val;
              }
            }
          });
          return h('div', [
            input,
            h('p', '127.0.0.1, 127.0.0.1:8080, 127.0.0.1/test.html?a=1')
          ]);
        },
        onOk: () => {
          let [addrs, ...path] = addr.split('/');

          path = '/' + path.join('/');

          let [ip, ...port] = addrs.split(':');

          if (!this.parseIPv4(ip)) {
            this.$Message.error(this.$t('Invalid address'));
            return;
          }

          if (port.length !== 0 && port.length !== 1) {
            this.$Message.error(this.$t('Invalid port'));
            return;
          }

          if (port.length === 1) {
            port = Number(port[0]);
            if (port <= 0 || port > 65535) {
              this.$Message.error(this.$t('Invalid port'));
              return;
            }
          } else {
            port = 80;
          }

          addr = encodeURIComponent(`${ip}:${port}${path}`);
          window.open(`/web/${devid}/${addr}`);
        }
      });
    },
    showCmdForm() {
      if (this.selection.length < 1) {
        this.$Message.error(
          this.$t('Please select the devices you want to operate')
        );
        return;
      }
      this.cmdModal = true;
    },
    delCmdParam(tag) {
      this.cmdData.params.splice(this.cmdData.params.indexOf(tag), 1);
    },
    showInputParam() {
      this.inputParamVisible = true;
      this.$nextTick(() => {
        this.$refs.inputParam.focus();
      });
    },
    doCmd() {
      this.$refs['cmdForm'].validate((valid) => {
        if (valid) {
          const selection = this.selection.filter((dev) => dev.online);

          this.cmdModal = false;
          this.cmdStatus.modal = true;
          this.cmdStatus.total = selection.length;
          this.cmdStatus.execing = selection.length;
          this.cmdStatus.fail = 0;
          this.cmdStatus.responses = [];

          selection.forEach((item) => {
            const data = {
              username: this.cmdData.username,
              password: this.cmdData.password,
              cmd: this.cmdData.cmd,
              params: this.cmdData.params
            };

            this.axios
              .post(`/cmd/${item.id}?wait=${this.cmdData.wait}`, data)
              .then((response) => {
                if (this.cmdData.wait === 0) {
                  this.cmdStatus.responses.push({
                    err: 0,
                    msg: '',
                    id: item.id,
                    code: 0,
                    stdout: '',
                    stderr: ''
                  });
                } else {
                  const resp = response.data;

                  if (resp.err && resp.err !== 0) {
                    this.cmdStatus.fail++;
                    resp.stdout = '';
                    resp.stderr = '';
                  } else {
                    resp.stdout = window.atob(resp.stdout || '');
                    resp.stderr = window.atob(resp.stderr || '');
                  }

                  resp.id = item.id;
                  this.cmdStatus.responses.push(resp);
                }
                this.cmdStatus.execing--;
              });
          });
        }
      });
    },
    resetCmdData() {
      this.$refs['cmdForm'].resetFields();
    },
    ignoreCmdResp() {
      this.cmdStatus.execing = 0;
      this.cmdStatus.respModal = true;
      this.cmdStatus.modal = false;
    },
    showCmdResp() {
      this.cmdStatus.modal = false;
      if (this.cmdStatus.responses.length > 0) this.cmdStatus.respModal = true;
    },
    handleInputParamConfirm() {
      const value = this.inputParamValue;
      if (value) {
        this.cmdData.params.push(value);
      }
      this.inputParamVisible = false;
      this.inputParamValue = '';
    },
    handleContextMenu(contextLine) {
      this.selection = [contextLine]
    },
    handleSelection(selection) {
      this.selection = JSON.parse(JSON.stringify(selection))
    },
    handleSearch() {
      this.filteredDevices = this.devlists.filter((d) => {
        const filterString = this.filterString.toLowerCase()
        return (
          d.id.toLowerCase().indexOf(filterString) > -1 ||
          d.description.toLowerCase().indexOf(filterString) > -1
        )
      })
    }
  },
  mounted() {
    this.username = sessionStorage.getItem('rttys-username') || '';

    this.axios.get('/isadmin').then((res) => {
      this.isadmin = res.data.admin;
    });

    this.getDevices();
  }
};
</script>

<style>
.ivu-card-head {
  line-height: 2 !important;
}
</style>