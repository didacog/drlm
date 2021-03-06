var BackupsTable = {
  props: ['backups'],
  template: `
    <div class="table-responsive">
      <table class="table table-hover">
        <caption>Backups</caption>
        <thead>
          <tr>
            <th>ID</th>
            <th>Client</th>
            <th>Date</th>
            <th>Status</th>
            <th>DR</th>
            <th>Duration</th>
            <th>Size</th>
            <th>PXE</th>
            <th>Config</th>
            <th>Type</th>
          </tr>
        </thead>
        <tbody v-for="backup in backups" v-bind:key="backup.idbackup">
          <tr>
            <td>{{ backup.idbackup }}</td>
            <td>{{ backup.clients_id }}</td>
            <td>{{ backup.date }}</td>
            <td v-if="backup.active == 1">enabled</td>
            <td v-else>disabled</td>
            <td>{{ backup.drfile }}</td>
            <td>{{ backup.duration }}</td>
            <td>{{ backup.size }}</td>
            <td v-if="backup.PXE == 1">*</td>
            <td v-else> </td>
            <td>{{ backup.config }}</td>
            <td>{{ backup.type }}-{{ backup.protocol }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  `
}

export default BackupsTable;
