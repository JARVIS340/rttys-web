<template>
  <div>
    <Header style="height: 50px; line-height: 50px; padding: 0px 20px;">
      <span style="float: right">
        <Dropdown @on-click="handleUserCommand" trigger="hover" >
          <a href="javascript:void(0)">
            <span style="color: #f7f7f7; font-size: 1.2rem; margin-right: 10px;">
              {{ username }}
              <span v-if="isadmin">@admin</span>
              <span v-else>@users</span>
            </span>

            <Icon type="ios-arrow-down" />
          </a>
          <DropdownMenu slot="list">
            <DropdownItem name="logout">
              {{ $t('Sign out') }}
            </DropdownItem>
          </DropdownMenu>
        </Dropdown>
      </span>
    </Header>
  </div>
</template>

<script>

export default {
  props: ['username', 'isadmin'],
  methods: {
    handleUserCommand(command) {
      if (command === 'logout') {
        this.axios.get('/signout').then(() => {
          this.$router.push('/login');
        });
      }
    }
  }
}
</script>