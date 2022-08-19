public with sharing class GC_TDTM {

	public interface BeforeInsert {
		void beforeInsert();
	}

	public interface AfterInsert {
		void afterInsert();
	}

	public interface BeforeUpdate {
		void beforeUpdate();
	}

	public interface AfterUpdate {
		void afterUpdate();
	}

	public interface BeforeDelete {
		void beforeDelete();
	}

	public interface AfterDelete {
		void afterDelete();
	}

	public interface AfterUndelete {
		void afterUndelete();
	}
}
